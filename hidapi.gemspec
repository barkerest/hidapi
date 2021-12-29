# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hidapi/version'

Gem::Specification.new do |spec|
  spec.name          = 'hidapi'
  spec.version       = HIDAPI::VERSION
  spec.authors       = ['Beau Barker']
  spec.email         = ['beau@barkerest.com']

  spec.summary       = 'A Ruby port of the HID API from Signal 11 Software (http://www.signal11.us/)'
  spec.homepage      = 'https://github.com/barkerest/hidapi'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version                = '>= 2.2.0'
  spec.add_dependency             'libusb',   '~> 0.6'
  spec.add_dependency             'i18n',     '~> 1.8'

  spec.add_development_dependency 'bundler',  '~> 2.3'
  spec.add_development_dependency 'rake',     '~> 13.0'
end
