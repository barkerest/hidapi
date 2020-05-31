#!/usr/bin/env ruby

require 'tmpdir'

module HIDAPI
  class SetupTaskHelper

    attr_reader :vendor_id, :product_id, :simple_name, :interface

    def initialize(vendor_id, product_id, simple_name, interface)
      @vendor_id = interpret_id(vendor_id)
      @product_id = interpret_id(product_id)
      @simple_name = simple_name.to_s.strip.gsub(' ', '_').gsub(/[^A-Za-z0-9_\-]/, '')
      @interface = interface.to_s.strip.to_i
      @temp_dir = Dir.mktmpdir('hidapi_setup')
      ObjectSpace.define_finalizer(self, ->{ FileUtils.rm_rf(@temp_dir) })
    end

    def uninstall
      if operating_system == :osx
        uninstall_osx
      else
        puts "Your operating system was detected as '#{operating_system}', but I don't have an uninstall routine for that."
      end
      true
    end

    def uninstall_osx

      target = "/System/Library/Extensions/#{simple_name}.kext"

      if not Dir.exist?(target)
        puts 'A kext with the specified name does not exist.'
        return false
      end

      puts 'Uninstalling kext...'
      `sudo rm -rf #{target}`
      `sudo touch /System/Library/Extensions`

      puts "The kext has been uninstalled.\nYou may have to unplug/plug the device or restart your computer."

      true
    end

    def run
      if valid_options?
        if operating_system == :osx
          run_osx
        elsif operating_system == :linux
          run_linux
        elsif operating_system == :windows
          run_windows
        else
          puts "Your operating system was detected as '#{operating_system}', but I don't have a setup routine for that."
          false
        end
      else
        usage
      end
    end

    def valid_options?
      vendor_id != 0 && product_id != 0 && simple_name != ''
    end

    def usage()
      puts <<-USAGE
Usage:  bundle exec rake setup_hid_device[vendor_id,product_id,simple_name,interface]
-OR-    #{File.basename(__FILE__)} vendor_id product_id simple_name interface
  vendor_id should be the 16-bit identifier assigned to the device vendor in hex format.
  product_id should be the 16-bit identifier assigned by the manufacturer in hex format.
  simple_name should be a fairly short name for the device.
  interface is optional and defaults to 0.

  ie - bundle exec rake setup_hid_device[04d8,c002,pico-lcd-graphic]
  ie - #{File.basename(__FILE__)} 04d8 c002 pico-lcd-graphic
USAGE
      false
    end

    private

    def operating_system
      @operating_system ||=
          begin

            # unix uses uname, windows uses ver.  failing both, use the OS environment variable (which can be specified by the user).
            kernel_name = `uname -s`.strip.downcase rescue nil
            kernel_name = `ver`.strip.downcase rescue nil unless kernel_name
            kernel_name = ENV['OS'].to_s.strip.downcase rescue '' unless kernel_name

            if /darwin/ =~ kernel_name
              :osx
            elsif /win/ =~ kernel_name
              :windows
            elsif /linux/ =~ kernel_name
              :linux
            else
              :unix
            end
          rescue
            :unknown
          end
    end

    def run_windows
      puts "Please use the Zadig tool from http://zadig.akeo.ie/ to install a driver for your device.\nThis script unfortunately does not do this for you automatically at this point in time."
    end

    def run_osx
      # OS X needs a codeless kext setup in the /System/Library/Extensions directory.

      path = @temp_dir
      path += '/' unless path[-1] == '/'
      path += simple_name

      target = "/System/Library/Extensions/#{simple_name}.kext"

      if Dir.exist?(target)
        puts 'A kext with the specified name already exists.'
        return false
      end

      puts 'Building kext...'
      Dir.mkdir path
      Dir.mkdir path + '/Contents'
      Dir.mkdir path + '/Contents/Resources'
      Dir.mkdir path + '/Contents/Resources/English.lproj'
      File.write path + '/Contents/Resources/English.lproj/InfoPlist.strings', "\nCFBundleName = \"VendorSpecificDriver\";\n"
      File.write path + '/Contents/Info.plist', <<-FILE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildMachineOSBuild</key>
	<string>11C74</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleIdentifier</key>
	<string>idv.barkerest.#{simple_name}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>KEXT</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
	<key>DTCompiler</key>
	<string></string>
	<key>DTPlatformBuild</key>
	<string>4D502</string>
	<key>DTPlatformVersion</key>
	<string>GM</string>
	<key>DTSDKBuild</key>
	<string>11C63</string>
	<key>DTSDKName</key>
	<string>macosx10.7</string>
	<key>DTXcode</key>
	<string>0421</string>
	<key>DTXcodeBuild</key>
	<string>4D502</string>
	<key>OSBundleRequired</key>
	<string>Console</string>
	<key>IOKitPersonalities</key>
	<dict>
    <key>#{simple_name}</key>
		<dict>
			<key>CFBundleIdentifier</key>
			<string>com.apple.kpi.iokit</string>
			<key>IOClass</key>
			<string>IOService</string>
			<key>IOProbeScore</key>
			<integer>11000</integer>
			<key>IOProviderClass</key>
			<string>IOUSBInterface</string>
			<key>bConfigurationValue</key>
			<integer>1</integer>
			<key>bInterfaceNumber</key>
			<integer>#{interface}</integer>
			<key>idProduct</key>
			<integer>#{product_id}</integer>
			<key>idVendor</key>
			<integer>#{vendor_id}</integer>
		</dict>
	</dict>
	<key>OSBundleLibraries</key>
	<dict>
		<key>com.apple.iokit.IOUSBFamily</key>
		<string>1.8</string>
		<key>com.apple.kernel.libkern</key>
		<string>6.0</string>
	</dict>
</dict>
</plist>
      FILE

      puts 'Installing kext...'
      `sudo cp -r #{path} #{target}`
      `sudo touch /System/Library/Extensions`

      FileUtils.rm_rf path

      puts "The kext has been installed.\nYou may have to unplug/plug the device or restart your computer."

      true
    end

    def run_linux
      # Linux needs a udev rule file added under /etc/udev/rules.d
      # We'll use '60-hidapi.rules' for our purposes.

      target = '/etc/udev/rules.d/60-hidapi.rules'

      contents = File.exist?(target) ? File.read(target) : nil
      contents ||= <<-DEF
# udev rules for libusb access created by Ruby 'hidapi' gem.
SUBSYSTEM!="usb", GOTO="hidapi_rules_end"
ACTION!="add", GOTO="hidapi_rules_end"

LABEL="hidapi_rules_end"
      DEF

      contents = contents.split("\n").map(&:strip)

      # get the position we will be inserting at.
      last_line = contents.index { |item| item == 'LABEL="hidapi_rules_end"' }

      contents.each do |line|
        if /^#\s+device:\s+#{simple_name}$/i =~ line
          puts 'A udev rule for the specified device already exists.'
          return false
        end
      end

      line = "# device: #{simple_name}\nATTR{idVendor}==\"#{vendor_id.to_s(16).rjust(4,'0')}\", ATTR{idProduct}==\"#{product_id.to_s(16).rjust(4,'0')}\", MODE=\"0666\", SYMLINK+=\"hidapi/#{simple_name}@%k\"\n"

      if last_line
        contents.insert last_line, line
      else
        contents << line
      end

      path = @temp_dir
      path += '/' unless path[-1] == '/'
      path += 'rules'

      File.write path, contents.join("\n")

      `sudo cp -f #{path} #{target}`

      File.delete path

      puts "A udev rule for the device has been created.\nYou may have to unplug/plug the device or restart your computer."
      true
    end

    private

    def interpret_id(id)
      id.is_a?(Integer) ? id : id.to_s.strip.to_i(16)
    end
  end
end


if $0 == __FILE__

  HIDAPI::SetupTaskHelper(ARGV[0], ARGV[1], ARGV[2], ARGV[3]).run

end
