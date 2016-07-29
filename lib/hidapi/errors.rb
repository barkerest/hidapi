module HidApi

  ##
  # A general error from the HidApi library.
  HidApiError = Class.new(StandardError)

  ##
  # The device supplied was invalid for the HidApi::Device class.
  InvalidDevice = Class.new(HidApiError)

  ##
  # Failed to open a device.
  DeviceOpenFailed = Class.new(HidApiError)

  ##
  # An open device is required for the method called.
  DeviceNotOpen = Class.new(HidApiError)
end