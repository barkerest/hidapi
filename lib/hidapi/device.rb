

module HIDAPI

  ##
  # This class is the interface to a HID device.
  #
  # Each instance can connect to a single interface on an HID device.
  # If you have more than one interface, you will need to have more
  # than one instance of this class to work with all of them.
  #
  # When open, the device is polled continuously for incoming data.
  # It will build up a cache of up to 32 packets.  If you are not
  # reading from the device, it will silently discard the oldest
  # packets and continue storing the newest packets.
  #
  # The read method can block.  This is controlled by the +blocking+
  # attribute.  The default value is true.  If you want the read method
  # to be non-blocking, set this attribute to false.
  class Device

    ##
    # Gets the USB device this HID device uses.
    attr_accessor :usb_device
    private :usb_device=

    ##
    # Gets the device handle for I/O.
    attr_accessor :handle
    private :handle=
    protected :handle

    ##
    # Gets the input endpoint.
    attr_accessor :input_endpoint
    private :input_endpoint=
    protected :input_endpoint

    ##
    # Gets the output endpoint.
    attr_accessor :output_endpoint
    private :output_endpoint=
    protected :output_endpoint

    ##
    # Gets the maximum packet size for input packets.
    attr_accessor :input_ep_max_packet_size
    private :input_ep_max_packet_size=
    protected :input_ep_max_packet_size

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
    # Gets the path for this device that can be used by HIDAPI::Engine#get_device_by_path
    attr_accessor :path
    private :path=

    attr_accessor :open_count
    private :open_count, :open_count=


    ##
    # Initializes an HID device.
    def initialize(usb_device, interface = 0)
      raise HIDAPI::InvalidDevice, "invalid object (#{usb_device.class.name})" unless usb_device.is_a?(LIBUSB::Device)

      self.usb_device = usb_device
      self.blocking   = true
      self.mutex      = Mutex.new
      self.interface  = interface
      self.path       = HIDAPI::Device.make_path(usb_device, interface)

      self.input_endpoint     = self.output_endpoint = nil
      self.thread             = nil
      self.thread_initialized = false
      self.input_reports      = []
      self.shutdown_thread    = false
      self.transfer_cancelled = LIBUSB::Context::CompletionFlag.new
      self.open_count         = 0

      self.class.init_hook.each do |proc|
        proc.call self
      end
    end



    ##
    # Gets the manufacturer of the device.
    def manufacturer
      @manufacturer ||= read_string(usb_device.iManufacturer, "VENDOR(0x#{vendor_id.to_hex(4)})").strip
    end

    ##
    # Gets the product/model of the device.
    def product
      @product ||= read_string(usb_device.iProduct, "PRODUCT(0x#{product_id.to_hex(4)})").strip
    end

    ##
    # Gets the serial number of the device.
    def serial_number
      @serial_number ||= read_string(usb_device.iSerialNumber, '?').strip
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
        HIDAPI.debug("open_count for device #{path} is #{open_count}") if open_count < 0
        if handle
          begin
            self.shutdown_thread = true
            transfer.cancel! rescue nil if transfer
            thread.join
          rescue =>e
            HIDAPI.debug "failed to kill read thread on device #{path}: #{e.inspect}"
          end
          begin
            handle.release_interface(interface)
          rescue =>e
            HIDAPI.debug "failed to release interface on device #{path}: #{e.inspect}"
          end
          begin
            handle.close
          rescue =>e
            HIDAPI.debug "failed to close device #{path}: #{e.inspect}"
          end
          HIDAPI.debug "closed device #{path}"
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
          HIDAPI.debug "open_count for open device #{path} is #{open_count}"
          self.open_count = 1
        end
        return self
      end
      self.open_count = 0
      begin
        self.handle = usb_device.open
        raise 'no handle returned' unless handle

        begin
          if handle.kernel_driver_active?(interface)
            handle.detach_kernel_driver(interface)
          end
        rescue LIBUSB::ERROR_NOT_SUPPORTED
          HIDAPI.debug 'cannot determine kernel driver status, continuing to open device'
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
        HIDAPI.debug "failed to open device #{path}: #{e.inspect}"
        raise DeviceOpenFailed, e.inspect
      end
      HIDAPI.debug "opened device #{path}"
      self.open_count = 1
      self
    end

    ##
    # Writes data to the device.
    #
    # The data to be written can be individual byte values, an array of byte values, or a string packed with data.
    def write(*data)
      raise ArgumentError, 'data must not be blank' if data.nil? || data.length < 1
      raise HIDAPI::DeviceNotOpen unless open?

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
          HIDAPI.debug "read data from device #{path}: #{data.inspect}"
          return data
        end

        if shutdown_thread
          HIDAPI.debug "read thread for device #{path} is not running"
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
              HIDAPI.debug "read data from device #{path}: #{data.inspect}"
              return data
            end
          end
          sleep 0
        end

        # error, return nil
        HIDAPI.debug "read thread ended while waiting on device #{path}"
        nil
      else
        # wait up to so many milliseconds for input.
        stop_at = Time.now + (milliseconds * 0.001)
        while Time.now < stop_at
          mutex.synchronize do
            if input_reports.count > 0
              data = input_reports.delete_at(0)
              HIDAPI.debug "read data from device #{path}: #{data.inspect}"
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
      raise HIDAPI::DeviceNotOpen unless open?

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
    def self.make_path(usb_dev, interface = 0)
      if usb_dev.is_a?(Hash)
        bus = usb_dev[:bus] || usb_dev['bus']
        address = usb_dev[:device_address] || usb_dev['device_address']
      else
        bus = usb_dev.bus_number
        address = usb_dev.device_address
      end
      "#{bus.to_hex(4)}:#{address.to_hex(4)}:#{interface.to_hex(2)}"
    end

    ##
    # Validates a device path.
    def self.validate_path(path)
      match = /(?<BUS>\d+):(?<ADDR>\d+):(?<IFACE>\d+)/.match(path)
      return nil unless match
      make_path(
          {
              bus: match['BUS'].to_i(16),
              device_address: match['ADDR'].to_i(16)
          },
          match['IFACE'].to_i(16)
      )
    end


    ##
    # Reads a string descriptor from the USB device.
    def read_string(index, on_failure = '')
      begin
        # does not require an interface, so open from the usb_dev instead of using our open method.
        data = if open?
                 handle.string_descriptor_ascii(index)
               else
                 usb_device.open { |handle| handle.string_descriptor_ascii(index) }
               end
        HIDAPI.debug("read string at index #{index} for device #{path}: #{data.inspect}")
        data
      rescue =>e
        HIDAPI.debug("failed to read string at index #{index} for device #{path}: #{e.inspect}")
        on_failure || ''
      end
    end


    protected

    ##
    # Defines a hook to execute when data is read from the device.
    #
    # This can be provided as a proc, symbol, or simply as a block.
    #
    # The proc should return a true value if it consumes the data.
    # If it does not consume the data it must return false or nil.
    #
    # If no read_hook proc consumes the data, it will be cached for
    # future calls to +read+ or +read_timeout+.
    #
    # The read hook is called from within the read thread. If it must
    # access resources from another thread, you will want to use
    # a mutex for locking.
    #
    # :yields: a device and the input_report
    #
    #   read_hook do |device, input_report|
    #     ...
    #     true
    #   end
    def self.read_hook(proc = nil, &block)
      @read_hook ||= []

      proc = block if proc.nil? && block_given?
      if proc
        if proc.is_a?(Symbol) || proc.is_a?(String)
          proc_name = proc
          proc = Proc.new do |dev, input_report|
            dev.send(proc_name, dev, input_report)
          end
        end
        @read_hook << proc
      end

      @read_hook
    end

    ##
    # Defines a hook to execute when a device is initialized.
    #
    # Yields the device instance.
    def self.init_hook(proc = nil, &block)
      @init_hook ||= []

      proc = block if proc.nil? && block_given?
      if proc
        if proc.is_a?(Symbol) || proc.is_a?(String)
          proc_name = proc
          proc = Proc.new do |dev|
            dev.send(proc_name, dev)
          end
        end
        @init_hook << proc
      end

      @init_hook
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
        HIDAPI.debug "failed to initialize read thread for device #{path}: #{e.inspect}"
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
          HIDAPI.debug "non-fatal error for read_thread on device #{path}: #{e.inspect}"
        rescue => e
          HIDAPI.debug "fatal error for read_thread on device #{path}: #{e.inspect}"
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
        data = tr.actual_buffer

        consumed = false
        self.class.read_hook.each do |proc|
          consumed =
              begin
                proc.call(self, data)
              rescue =>e
                HIDAPI.debug "read_hook failed for device #{path}: #{e.inspect}"
                false
              end
          break if consumed
        end

        unless consumed
          mutex.synchronize do
            input_reports << tr.actual_buffer
            input_reports.delete_at(0) while input_reports.length > 32
          end
        end
      elsif tr.status == :TRANSFER_CANCELLED
        mutex.synchronize do
          self.shutdown_thread = true
          transfer_cancelled.completed = true
        end
        HIDAPI.debug "read transfer cancelled for device #{path}"
      elsif tr.status == :TRANSFER_NO_DEVICE
        mutex.synchronize do
          self.shutdown_thread = true
          transfer_cancelled.completed = true
        end
        HIDAPI.debug "read transfer failed with no device for device #{path}"
      elsif tr.status == :TRANSFER_TIMED_OUT
        # ignore timeouts, they are normal
      else
        HIDAPI.debug "read transfer with unknown transfer code (#{tr.status}) for device #{path}"
      end

      # resubmit the transfer object.
      begin
        tr.submit!
      rescue =>e
        HIDAPI.debug "failed to resubmit transfer for device #{path}: #{e.inspect}"
        mutex.synchronize do
          self.shutdown_thread = true
          transfer_cancelled.completed = true
        end
      end
    end


  end
end