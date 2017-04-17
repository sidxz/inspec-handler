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
inspec_handler 'name' do
  run_path              String
  log_path              String
  enforced              TrueClass, FalseClass
  action                Symbol, :hard_run if not specified
end
```
where
* inspec_handler is the resource
* run_path is the dir in which inspec test suites reside. The tests inside this dir is arranged by cookbook-name/recipe-name.rb. recipe-name.rb contains inspec test code for the corresponding recipe.
* log_path is a file where the logs will be stored.
* enforced will enforce a rule that enforces each recipe that exists in the runlist to have a corresponding inspec test suite inside run_path. By default this is set to true. The chef client-run will fail if a missing test suite is detected. Set this to false to revoke the restriction.

# Actions
