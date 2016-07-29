# HidApi

This is a Ruby port of the [HID API from Signal 11](http://www.signal11.us/oss/hidapi).
  
__I am not associated with Signal 11.__

More specifically, it is a 
port of the "libusb" version of the HID API.  I took creative liberty where I needed to and basically just sought to 
make it work uniformly.  The gem relies on the [libusb](https://rubygems.org/gems/libusb).

 
I know there are at least two other projects that were meant to bring an HID API to the Ruby world.  However, one of
them is a C plugin (no real problem, just not Ruby) and the other is an FFI wrapper around the original HID API with
a few missing components.  I didn't see any reason to bring FFI into it when the end result is something fairly simple.

The entire library basically consists of the HidApi::Engine and the HidApi::Device classes.  The HidApi module maintains
an instance of the HidApi::Engine and maps missing methods to the engine.  So basically `HidApi.enumerate` is the same
as `HidApi.engine.enumerate` where the `engine` method creates an HidApi::Engine on the first call.  The HidApi::Engine
class is used to enumerate and retrieve devices, while the HidApi::Device class is used for everything else.

The original source included internationalization.  I have not included that (yet), but the HidApi::Language class has
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
my_dev = HidApi::open(0x4d4d, 0xc0c0)
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

In order to use a USB device in Linux, udev needs to grant access to the user running the application.  If run as root, 
then it should just work.  However, you'd be running it as root.  A better option is to have udev grant the appropriate permissions.

In order to use a USB device in OS X, the system needs a kernel extension telling the OS not to map the device to its own
HID drivers.

The `HidApi::SetupTaskHelper` handles both of these situations.  The gem includes a rake task `setup_hid_device` that 
calls this class.  You can also execute the `lib/hidapi/setup_task_helper.rb` file directly.  However, in your application,
both of these may be too cumbersome.  You can create an instance of the SetupTaskHelper class with the appropriate arguments
and just run it yourself.

```ruby
require "hidapi"
HidApi::SetupTaskHelper.new(
  0x04d8,             # vendor_id
  0xc002,             # product_id
  "pico-lcd-graphic", # simple_name
  0                   # interface
).run
```

This will take the appropriate action on your OS to make the USB device available for use.  On linux, it will also add
convenient symlinks to the /dev filesystem.  For instance, the above setup could give you something like `/dev/hidapi/pico-lcd-graphic@1-4`
that points to the correct USB device.  The library doesn't use them, but the presence of the links in the`/dev/hidapi`
directory would be a clear indicator that the device has been recognizes and configured.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkerest/hidapi.


## License

Copyright (c) 2016 [Beau Barker](mailto:beau@barkerest.com)

As said before, this is a port of the [HID API from Signal 11](http://www.signal11.us/oss/hidapi) so it has significant
code in common with that library, although the very fact that it was ported means that there is no code that was copied
from that library.  That library can be licensed under the GPL, BSD, or a custom license very similar to the MIT license.
This gem is not that library.

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

