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
  environment %w(_quality)
  action [:hard_run]
end
