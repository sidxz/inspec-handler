# Inspec handler
Use inspec_handler resource to automatically run a set of inspec tests in the client's machine at the last phase of the chef-client run.

# Usage
inspec_handler resource  in your cookbook will run all the inspec tests for all the recipes that exists in your run list.
These tests are placed in the client node at a certain directory defined by the run_path.

```ruby
inspec_handler "Run Active Tests" do
  run_path "/etc/chef/inspec-handler"
  enforced true
  action [:hard_run]
```
The full syntax for all the properties that are available to the inspec_handler resource is:
```ruby
resource_handler 'name' do
  run_path              String
  log_path              String
  enforced              TrueClass, FalseClass
  action                Symbol, :hard_run if not specified
end
```
