#
# Cookbook:: inspec_handler
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#
#
inspec_handler "all-tests" do
  run_path '/opt/coe/inspec-tests'
  enforced false
  action [:hard_run]
end