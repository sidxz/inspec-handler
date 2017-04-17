# Inspec handler

ww
# Usage
A inspec_handler in your cookbook will run all the inspec tests for all the recipes that exists in your run listresource .
These tests are placed in the client node at a certain directory.

```ruby
inspec_handler "Run Active Tests" do
  run_path "/etc/chef/inspec-handler"
  enforced true
  action [:hard_run]
```

