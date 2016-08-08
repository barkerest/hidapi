require 'libusb'
require 'hidapi/version'

##
# A Ruby implementation of the HID API library from Signal 11 software.
#
# I am not associated with Signal 11 software.
#
# This library was written out of a need to get better debugging information.
# By writing it, I learned quite a bit about HID devices and how to get them
# working with multiple operating systems from one Ruby gem. To do this, I use LIBUSB.
#
# This module contains the library and wraps around an instance of the HIDAPI::Engine
# class to simplify calls.  For instance, HIDAPI.engine.enumerate can also be used as
# just HIDAPI.enumerate.
#
module HIDAPI

  raise 'LIBUSB version must be at least 1.0' unless LIBUSB.version.major >= 1

  ##
  # Gets the engine used by the API.
  #
  # All engine methods can be passed through the HIDAPI module.
  def self.engine
    @engine ||= HIDAPI::Engine.new
  end


  def self.method_missing(m,*a,&b)    # :nodoc:
    if engine.respond_to?(m)
      engine.send(m,*a,&b)
    else
      # no super available for modules.
      raise NoMethodError, "undefined method `#{m}` for HIDAPI:Module"
    end
  end


  def self.respond_to_missing?(m)     # :nodoc:
    engine.respond_to?(m)
  end


  ##
  # Processes a debug message.
  #
  # You can either provide a debug message directly or via a block.
  # If a block is provided, it will not be executed unless a debugger has been set and the message is left nil.
  def self.debug(msg = nil, &block)
    dbg = @debugger
    if dbg
      mutex.synchronize do
        msg = block.call if block_given? && msg.nil?
        dbg.call(msg)
      end
    end
  end

  ##
  # Sets the debugger to use.
  #
  # :yields: the message to debug
  def self.set_debugger(&block)
    mutex.synchronize do
      @debugger = block_given? ? block : nil
    end
  end

  private

  def self.mutex
    @mutex ||= Mutex.new
  end


  if ENV['ENABLE_DEBUG'].to_s.to_i != 0
    set_debugger do |msg|
      msg = msg.to_s.strip
      if msg.length > 0
        @debug_file ||= File.open(File.expand_path('../../tmp/debug.log', __FILE__), 'w')
        @debug_file.write "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{msg.gsub("\n", "\n" + (' ' * 22))}\n"
        @debug_file.flush
        STDOUT.print "(debug) #{msg.gsub("\n", "\n" + (' ' * 8))}\n"
      end
    end
  end

end

# load all of the library components.
Dir.glob(File.expand_path('../hidapi/*.rb', __FILE__)) { |file| require file }
