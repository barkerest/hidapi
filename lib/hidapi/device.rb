

module HidApi
  class Device

    ##
    # Gets the USB device this HID device uses.
    attr_accessor :usb_device
    private :usb_device

    attr_accessor :handle
    private :handle, :handle=

    attr_accessor :input_endpoint
    private :input_endpoint, :input_endpoint=

    attr_accessor :output_endpoint
    private :output_endpoint, :output_endpoint=

    attr_accessor :input_ep_max_packet_size
    private :input_ep_max_packet_size, :input_ep_max_packet_size=

    ##
    # Gets the interface this HID device uses on the USB device.
    attr_accessor :interface
    private :interface=

    ##
    # Gets or sets the blocking nature for +read+.
    #
    # Defaults to +true+.  Set to +false+ to have +read+ be non-blocking.
    attr_accessor :blocking

    attr_accessor :thread
    private :thread, :thread=

    attr_accessor :mutex
    private :mutex, :mutex=

    attr_accessor :thread_initialized
    private :thread_initialized, :thread_initialized=

    attr_accessor :shutdown_thread
    private :shutdown_thread, :shutdown_thread=

    attr_accessor :transfer_cancelled
    private :transfer_cancelled, :transfer_cancelled=

    attr_accessor :transfer
    private :transfer, :transfer=

    attr_accessor :input_reports
    private :input_reports, :input_reports=

    ##
    # Gets the path for this device that can be used by HidApi::Engine#get_by_path
    attr_accessor :path
    private :path=

    attr_accessor :open_count
    private :open_count, :open_count=


    ##
    # Initializes an HID device.
    def initialize(usb_device, interface = 0)
      raise HidApi::InvalidDevice, "invalid object (#{usb_device.class.name})" unless usb_device.is_a?(LIBUSB::Device)

      self.usb_device = usb_device
      self.blocking   = true
      self.mutex      = Mutex.new
      self.interface  = interface
      self.path       = HidApi::Device.make_path(usb_device, interface)

      self.input_endpoint     = self.output_endpoint = nil
      self.thread             = nil
      self.thread_initialized = false
      self.input_reports      = []
      self.shutdown_thread    = false
      self.transfer_cancelled = LIBUSB::Context::CompletionFlag.new
      self.open_count         = 0
    end



    ##
    # Gets the manufacturer of the device.
    def manufacturer
      @manufacturer ||= get_usb_string(usb_device.iManufacturer, "VENDOR(0x#{vendor_id.to_hex(4)})").strip
    end

    ##
    # Gets the product/model of the device.
    def product
      @product ||= get_usb_string(usb_device.iProduct, "PRODUCT(0x#{product_id.to_hex(4)})").strip
    end

    ##
    # Gets the serial number of the device.
    def serial_number
      @serial_number ||= get_usb_string(usb_device.iSerialNumber, '?').strip
    end

    ##
    # Gets the vendor ID.
    def vendor_id
      @vendor_id ||= usb_device.idVendor
    end

    ##
    # Gets the product ID.
    def product_id
      @product_id ||= usb_device.idProduct
    end

    ##
    # Is the device currently open?
    def open?
      !!handle
    end

    ##
    # Closes the device (if open).
    #
    # Returns the device.
    def close
      self.open_count = open_count - 1
      if open_count <= 0
        HidApi.debug("open_count for device #{path} is #{open_count}") if open_count < 0
        if handle
          begin
            self.shutdown_thread = true
            transfer.cancel! rescue nil if transfer
            thread.join
          rescue =>e
            HidApi.debug "failed to kill read thread on device #{path}: #{e.inspect}"
          end
          begin
            handle.release_interface(interface)
          rescue =>e
            HidApi.debug "failed to release interface on device #{path}: #{e.inspect}"
          end
          begin
            handle.close
          rescue =>e
            HidApi.debug "failed to close device #{path}: #{e.inspect}"
          end
          HidApi.debug "closed device #{path}"
        end
        self.handle = nil
        mutex.synchronize { self.input_reports = [] }
        self.open_count = 0
      end
      self
    end

    ##
    # Opens the device.
    #
    # Returns the device.
    def open
      if open?
        self.open_count = open_count + 1
        if open_count < 1
          HidApi.debug "open_count for open device #{path} is #{open_count}"
          self.open_count = 1
        end
        return self
      end
      self.open_count = 0
      begin
        self.handle = usb_device.open
        raise 'no handle returned' unless handle

        if handle.kernel_driver_active?(interface)
          handle.detach_kernel_driver(interface)
        end

        handle.claim_interface(interface)

        self.input_endpoint = self.output_endpoint = nil

        # now we need to find the endpoints.
        usb_device.settings
            .keep_if {|item| item.bInterfaceNumber == interface}
            .each do |intf_desc|
          intf_desc.endpoints.each do |ep|
            if ep.transfer_type == :interrupt
              if input_endpoint.nil? && ep.direction == :in
                self.input_endpoint = ep.bEndpointAddress
                self.input_ep_max_packet_size = ep.wMaxPacketSize
              end
              if output_endpoint.nil? && ep.direction == :out
                self.output_endpoint = ep.bEndpointAddress
              end
            end
            break if input_endpoint && output_endpoint
          end
        end

        # output_ep is optional, input_ep is required
        raise 'failed to locate input endpoint' unless input_endpoint

        # start the read thread
        self.input_reports = []
        self.thread_initialized = false
        self.shutdown_thread = false
        self.thread = Thread.start(self) { |dev| dev.send(:execute_read_thread) }
        sleep 0 until thread_initialized

      rescue =>e
        handle.close rescue nil
        self.handle = nil
        HidApi.debug "failed to open device #{path}: #{e.inspect}"
        raise DeviceOpenFailed, e.inspect
      end
      HidApi.debug "opened device #{path}"
      self.open_count = 1
      self
    end

    ##
    # Writes data to the device.
    #
    # The data to be written can be individual byte values, an array of byte values, or a string packed with data.
    def write(*data)
      raise ArgumentError, 'data must not be blank' if data.nil? || data.length < 1
      raise HidApi::DeviceNotOpen unless open?

      data, report_number, skipped_report_id = clean_output_data(data)

      if output_endpoint.nil?
        # No interrupt out endpoint, use the control endpoint.
        handle.control_transfer(
            bmRequestType: LIBUSB::REQUEST_TYPE_CLASS | LIBUSB::RECIPIENT_INTERFACE | LIBUSB::ENDPOINT_OUT,
            bRequest: 0x09,   # HID Set_Report
            wValue: (2 << 8) | report_number,  # HID output = 2
            wIndex: interface,
            dataOut: data
        )
        data.length + (skipped_report_id ? 1 : 0)
      else
        # Use the interrupt out endpoint.
        handle.interrupt_transfer(
            endpoint: output_endpoint,
            dataOut: data
        )
      end
    end

    ##
    # Attempts to read from the device, waiting up to +milliseconds+ before returning.
    #
    # If milliseconds is less than 1, it will wait forever.
    # If milliseconds is 0, then it will return immediately.
    #
    # Returns the next report on success.  If no report is available and it is not waiting
    # forever, it will return an empty string.
    #
    # Returns nil on error.
    def read_timeout(milliseconds)
      raise DeviceNotOpen unless open?

      mutex.synchronize do
        if input_reports.count > 0
          data = input_reports.delete_at(0)
          HidApi.debug "read data from device #{path}: #{data.inspect}"
          return data
        end

        if shutdown_thread
          HidApi.debug "read thread for device #{path} is not running"
          return nil
        end
      end

      # no data to return, do not block.
      return '' if milliseconds == 0

      if milliseconds < 0
        # wait forever (as long as the read thread doesn't die)
        until shutdown_thread
          mutex.synchronize do
            if input_reports.count > 0
              data = input_reports.delete_at(0)
              HidApi.debug "read data from device #{path}: #{data.inspect}"
              return data
            end
          end
          sleep 0
        end

        # error, return nil
        HidApi.debug "read thread ended while waiting on device #{path}"
        nil
      else
        # wait up to so many milliseconds for input.
        stop_at = Time.now + (milliseconds * 0.001)
        while Time.now < stop_at
          mutex.synchronize do
            if input_reports.count > 0
              data = input_reports.delete_at(0)
              HidApi.debug "read data from device #{path}: #{data.inspect}"
              return data
            end
          end
          sleep 0
        end

        # no input, return empty.
        ''
      end
    end

    ##
    # Reads the next report from the device.
    #
    # In blocking mode, it will wait for a report.
    # In non-blocking mode, it will return immediately with an empty string if there is no report.
    #
    # Returns nil on error.
    def read
      read_timeout blocking? ? -1 : 0
    end

    ##
    # Is this device in blocking mode (for reading)?
    def blocking?
      !!blocking
    end

    ##
    # Sends a feature report to the device.
    def send_feature_report(data)
      raise ArgumentError, 'data must not be blank' if data.nil? || data.length < 1
      raise HidApi::DeviceNotOpen unless open?

      data, report_number, skipped_report_id = clean_output_data(data)

      handle.control_transfer(
          bmRequestType: LIBUSB::REQUEST_TYPE_CLASS | LIBUSB::RECIPIENT_INTERFACE | LIBUSB::ENDPOINT_OUT,
          bRequest: 0x09,   # HID Set_Report
          wValue: (3 << 8) | report_number,   # HID feature = 3
          wIndex: interface,
          dataOut: data
      )

      data.length + (skipped_report_id ? 1 : 0)
    end

    ##
    # Gets a feature report from the device.
    def get_feature_report(report_number, buffer_size = nil)

      buffer_size ||= input_ep_max_packet_size

      handle.control_transfer(
          bmRequestType: LIBUSB::REQUEST_TYPE_CLASS | LIBUSB::RECIPIENT_INTERFACE | LIBUSB::ENDPOINT_IN,
          bRequest: 0x01,   # HID Get_Report
          wValue: (3 << 8) | report_number,
          wIndex: interface,
          dataIn: buffer_size
      )

    end


    def inspect   # :nodoc:
      "#<#{self.class.name}:0x#{self.object_id.to_hex(16)} #{vendor_id.to_hex(4)}:#{product_id.to_hex(4)} #{manufacturer} #{product} #{serial_number} (#{open? ? 'OPEN' : 'CLOSED'})>"
    end


    def to_s      # :nodoc:
      "#{manufacturer} #{product} (#{serial_number})"
    end


    ##
    # Generates a path for a device.
    def self.make_path(usb_dev, interface)
      bus = usb_dev.bus_number
      address = usb_dev.device_address
      "#{bus.to_hex(4)}:#{address.to_hex(4)}:#{interface.to_hex(2)}"
    end


    private

    def clean_output_data(data)
      if data.length == 1 && data.first.is_a?(Array)
        data = data.first
      end

      if data.length == 1 && data.first.is_a?(String)
        data = data.first
      end

      data = data.pack('C*') unless data.is_a?(String)

      skipped_report_id = false
      report_number = data.getbyte(0)

      if report_number == 0x00
        data = data[1..-1].to_s
        skipped_report_id = true
      end

      [ data, report_number, skipped_report_id ]
    end

    def execute_read_thread

      begin
        # make it available locally, prevent changes while we are running.
        length = input_ep_max_packet_size
        context = usb_device.context

        # Construct our transfer.
        self.transfer = LIBUSB::InterruptTransfer.new(
            dev_handle: handle,
            endpoint: input_endpoint,
            callback: method(:read_callback),
            timeout: 30000
        )
        transfer.alloc_buffer length

        # clear flag for transfer cancellation.
        transfer_cancelled.completed = false

        # perform the initial submission, the callback will resubmit.
        transfer.submit!
      rescue =>e
        HidApi.debug "failed to initialize read thread for device #{path}: #{e.inspect}"
        self.shutdown_thread = true
        raise e
      ensure
        # tell the main thread that we are running.
        self.thread_initialized = true
      end

      # wait for the main thread to kill this thread.
      until shutdown_thread
        begin
          context.handle_events 0
        rescue LIBUSB::ERROR_BUSY, LIBUSB::ERROR_TIMEOUT, LIBUSB::ERROR_OVERFLOW, LIBUSB::ERROR_INTERRUPTED => e
          # non fatal errors.
          mutex.synchronize { HidApi.debug "non-fatal error for read_thread on device #{path}: #{e.inspect}" }
        rescue => e
          mutex.synchronize { HidApi.debug "fatal error for read_thread on device #{path}: #{e.inspect}" }
          self.shutdown_thread = true
          raise e
        end
      end

      # no longer running.
      self.thread_initialized = false

      # cancel any transfers that may be pending.
      transfer.cancel! rescue nil

      # wait for the cancellation to complete.
      until transfer_cancelled.completed?
        context.handle_events 0, transfer_cancelled
      end

    end

    def read_callback(tr)
      if tr.status == :TRANSFER_COMPLETED
        mutex.synchronize do
          input_reports << tr.actual_buffer
          input_reports.delete_at(0) while input_reports.length > 30
        end
      elsif tr.status == :TRANSFER_CANCELLED
        mutex.synchronize do
          self.shutdown_thread = true
          transfer_cancelled.completed = true
          HidApi.debug "read transfer cancelled for device #{path}"
        end
      elsif tr.status == :TRANSFER_NO_DEVICE
        mutex.synchronize do
          self.shutdown_thread = true
          transfer_cancelled.completed = true
          HidApi.debug "read transfer failed with no device for device #{path}"
        end
      elsif tr.status == :TRANSFER_TIMED_OUT
        # ignore timeouts, they are normal
      else
        mutex.synchronize { HidApi.debug "read transfer with unknown transfer code (#{tr.status}) for device #{path}" }
      end

      # resubmit the transfer object.
      begin
        tr.submit!
      rescue =>e
        mutex.synchronize do
          HidApi.debug "failed to resubmit transfer for device #{path}: #{e.inspect}"
          self.shutdown_thread = true
          transfer_cancelled.completed = true
        end
      end
    end

    ##
    # Gets a string descriptor from the USB device.
    #
    # Almost identical to try_string_descriptor_ascii, except we allow the failure value to be specified.
    def get_usb_string(index, on_failure = '')
      begin
        # does not require an interface, so open from the usb_dev instead of using our open method.
        data = usb_device.open { |handle| handle.string_descriptor_ascii(index) }
        HidApi.debug("read string at index #{index} for device #{path}: #{data.inspect}")
        data
      rescue =>e
        HidApi.debug("failed to read string at index #{index} for device #{path}: #{e.inspect}")
        on_failure || ''
      end
    end


  end
end