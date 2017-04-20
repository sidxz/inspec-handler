default['inspec_handler']['run_path'] = "/etc/chef/inspec-handler"
default['inspec_handler']['log_path'] = "/var/log/inspec_handler" 
default['inspec_handler']['enforced'] = true
default['inspec_handler']['whitelist']= nil
default['inspec_handler']['blacklist']= nil
default['inspec_handler']['environment']= nil
default['inspec_handler']['action']= :hard_run
