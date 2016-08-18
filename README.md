# HIDAPI

This is a Ruby port of the [HID API from Signal 11](http://www.signal11.us/oss/hidapi).
  
__I am not associated with Signal 11.__

More specifically, it is a 
port of the "libusb" version of the HID API.  I took creative liberty where I needed to and basically just sought to 
make it work uniformly.  The gem relies on the [libusb](https://rubygems.org/gems/libusb).

 
I know there are at least two other projects that were meant to bring an HID API to the Ruby world.  However, one of
them is a C plugin (no real problem, just not Ruby) and the other is an FFI wrapper around the original HID API with
a few missing components.  I didn't see any reason to bring FFI into it when the end result is something fairly simple.

The entire library basically consists of the HIDAPI::Engine and the HIDAPI::Device classes.  The HIDAPI module maintains
an instance of the HIDAPI::Engine and maps missing methods to the engine.  So basically `HIDAPI.enumerate` is the same
as `HIDAPI.engine.enumerate` where the `engine` method creates an HIDAPI::Engine on the first call.  The HIDAPI::Engine
class is used to enumerate and retrieve devices, while the HIDAPI::Device class is used for everything else.

The original source included internationalization.  I have not included that (yet), but the HIDAPI::Language class has
been defined and the [i18n](https://rubygems.org/gems/i18n) is required, even though we aren't using it yet.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hidapi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hidapi


## Usage

Basic usage would be as follows.
```ruby
my_dev = HIDAPI::open(0x4d4d, 0xc0c0)
my_dev.write 0x01, 0x02, 0x03, 0x04, 0x05
my_dev.write [ 0x01, 0x02, 0x03, 0x04, 0x05 ]
my_dev.write "\x01\x02\x03\x04\x05"
input = my_dev.read
my_dev.close
```
The `write` method takes data in any of the 3 forms shown above. Individual arguments, an array of arguments, or a string of arguments.
Internally the first two are converted into the 3rd form using `pack("C*")`.  If you have a custom data set your are sending,
such as 16 or 32 bit values, then you will likely want to pack the string yourself to prevent issues.

The `read` method returns a packed string from the device.  For instance it may return "\x10\x01\x00".  Your application
needs to know how to handle the values returned.

There are multiple methods to open a device.
```ruby
vendor_id = 0x4d4d
product_id = 0xc0c0
serial_number = '123456'
bus_number = 1
device_address = 12
interface = 0
dev_hidapi_path = "/dev/hidapi/my-dev@1-2.3"
dev_raw_path = "/dev/bus/usb/001/00c"

# open with just the vendor and product id.  first match is returned.
my_dev = HIDAPI::open(vendor_id, product_id)

# extend that by also including the serial number. first match is returned, 
# but this time it should definitely be unique
my_dev = HIDAPI::open(vendor_id, product_id, serial_number)

# (linux only) open the device using the hidapi path.
my_dev = HIDAPI::open_path(dev_hidapi_path)

# (linux only) open the device using the raw dev path.
my_dev = HIDAPI::open_path(dev_raw_path)

# open the device using the BUS:ADDRESS:INTERFACE path.
# the components of the path must be in hexadecimal.
my_dev = HIDAPI::open_path("#{bus_number.to_s(16)}:#{device_address.to_s(16)}:#{interface.to_s(16)}")
```

Because USB is hot-pluggable, you may want to avoid the `open_path` method unless your device is guaranteed to be plugged
into the same port all the time.  For instance, a device plugged into a port inside the computer case.  Devices plugged
into external ports, or hubs, are not necessarily good candidates for `open_path` because they can be unplugged and plugged
into a different port at any time.  A device at "001:00c:00" may be at "001:00b:00" the next time because the user swapped
the plug into another port.

If you will only have one instance of the device plugged in, it is best to use the `open` method with the vendor_id and 
product_id of the device.  If you have multiple instances and they each have unique serial numbers, then you would want
to use the `open` method with the vendor_id, product_id, and serial_number.  If you have multiple instances with the same
serial number (because it is hardcoded into the firmware for example), then you will need to use dedicated ports and 
`open_path`.


In order to use a USB device in Linux, udev needs to grant access to the user running the application.  If run as root, 
then it should just work.  However, you'd be running it as root.  A better option is to have udev grant the appropriate permissions.

In order to use a USB device in OS X, the system needs a kernel extension telling the OS not to map the device to its own
HID drivers.

In order to use a USB device in Windows, the system needs the WinUSB driver installed for the device.  Please use the 
[Zadig tool](http://zadig.akeo.ie/) to install the driver for your device.  Even then Windows seems quirky with libusb. 
The biggest problem I have noticed is the inability to close a device without exiting the program.  I haven't thoroughly
investigated it yet because Windows has not been my primary development environment.  I would appreciate any feedback related
to this issue.

The `HIDAPI::SetupTaskHelper` handles Linux and OS X situations.  The gem includes a rake task `setup_hid_device` that 
calls this class.  You can also execute the `lib/hidapi/setup_task_helper.rb` file directly.  However, in your application,
both of these may be too cumbersome.  You can create an instance of the SetupTaskHelper class with the appropriate arguments
and just run it yourself.

```ruby
require "hidapi"
HIDAPI::SetupTaskHelper.new(
  0x04d8,             # vendor_id
  0xc002,             # product_id
  "pico-lcd-graphic", # simple_name
  0                   # interface
).run
```

This will take the appropriate action on your OS to make the USB device available for use.  On linux, it will also add
convenient symlinks to the /dev filesystem.  For instance, the above setup could give you something like `/dev/hidapi/pico-lcd-graphic@1-4`
that points to the correct USB device.  The library can use these links to open the device, and the presence of the links in the`/dev/hidapi`
directory would be a clear indicator that the device has been recognized and configured.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkerest/hidapi.


## License

Copyright (c) 2016 [Beau Barker](mailto:beau@barkerest.com)

As said before, this is a port of the [HID API from Signal 11](http://www.signal11.us/oss/hidapi) so it has significant
code in common with that library, although the very fact that it was ported means that there is no code that was copied
from that library.  That library can be licensed under the GPL, BSD, or a custom license very similar to the MIT license.
This gem is not that library.

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

