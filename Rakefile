require "bundler/gem_tasks"
require 'hidapi/setup_task_helper'

desc 'Setup an HID device for use with the library'
task :setup_hid_device, :vendor_id, :product_id, :simple_name, :interface do |t,args|
  args ||= {}
  helper = HidApi::SetupTaskHelper.new(args[:vendor_id], args[:product_id], args[:simple_name], args[:interface])
  helper.run
end

task :default => :spec
