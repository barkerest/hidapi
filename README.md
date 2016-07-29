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

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hidapi.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

