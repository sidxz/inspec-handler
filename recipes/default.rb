#
# Cookbook:: inspec_handler
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#
#

# Start inspec handler
inspec_handler "inspec_tests" do
  run_path                      node['inspec_handler']['run_path']
  log_path                      node['inspec_handler']['log_path']
  log_shift_age                 node['inspec_handler']['log_shift_age']
  enforced                      node['inspec_handler']['enforced']
  abort_on_fail                 node['inspec_handler']['abort_on_fail']
  whitelist                     node['inspec_handler']['whitelist']
  blacklist                     node['inspec_handler']['blacklist']
  test_environment              node['inspec_handler']['test_environment']
  production_environment        node['inspec_handler']['production_environment']
  action :nothing
  delayed_action  node['inspec_handler']['action']
end
