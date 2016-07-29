
module HidApi
  class Engine

    ##
    # Contains the class code for HID devices from LIBUSB.
    HID_CLASS = LIBUSB::CLASS_HID

    ##
    # Creates a new engine.
    def initialize
      @context = LIBUSB::Context.new
    end


    ##
    # Enumerates the HID devices matching the vendor and product IDs.
    #
    # Both vendor_id and product_id are optional.  They will act as a wild card if set to 0 (the default).
    def enumerate(vendor_id = 0, product_id = 0)
      raise HidApi::HidApiError, 'not initialized' unless @context

      filters = { bClass: HID_CLASS }

      unless vendor_id.nil? || vendor_id.to_i == 0
        filters[:idVendor] = vendor_id.to_i
      end
      unless product_id.nil? || product_id.to_i == 0
        filters[:idProduct] = product_id.to_i
      end

      list = @context.devices(filters)

      list.map{|dev| HidApi::Device.new(dev)}
    end

    ##
    # Gets the first device with the specified vendor_id, product_id, and optionally serial_number.
    def get_device(vendor_id, product_id, serial_number = nil)
      raise ArgumentError, 'vendor_id must be provided' if vendor_id.to_i == 0
      raise ArgumentError, 'product_id must be provided' if product_id.to_i == 0
      list = enumerate(vendor_id, product_id)
      return nil unless list && list.count > 0
      return list.first if serial_number.to_s == ''
      list.each do |dev|
        return dev if dev.serial_number == serial_number
      end
      nil
    end

    ##
    # Opens the first device with the specified vendor_id, product_id, and optionally serial_number.
    def open(vendor_id, product_id, serial_number = nil)
      dev = get_device(vendor_id, product_id, serial_number)
      dev.open if dev
    end

    ##
    # Gets the device with the specified path.
    def get_device_by_path(path)
      enumerate.each do |usb_dev|
        usb_dev.settings.each do |intf_desc|
          if intf_desc.bInterfaceClass == HID_CLASS
            dev_path = HidApi::make_path(usb_dev, intf_desc.bInterfaceNumber)
            if dev_path == path
              return HidApi::Device.new(usb_dev.usb_device, intf_desc.bInterfaceNumber)
            end
          end
        end
      end
    end

    ##
    # Opens the device with the specified path.
    def open_by_path(path)
      dev = get_device_by_path(path)
      dev.open if dev
    end

    ##
    # Gets the USB code for the current locale.
    def usb_code_for_current_locale
      @usb_code_for_current_locale ||=
          begin
            locale = I18n.locale
            if locale
              locale = locale.to_s.partition('.')[0]  # remove encoding
              result = HidApi::Language.get_by_code(locale)
              unless result
                locale = locale.partition('_')[0]     # chop off extra specification
                result = HidApi::Language.get_by_code(locale)
              end
              result ? result[:usb_code] : 0
            else
              0
            end
          end
    end


    def inspect
      "#<#{self.class.name}:#{self.object_id.to_hex(16)} context=0x#{@context.object_id.to_hex(16)}>"
    end

    def to_s
      inspect
    end

  end
end