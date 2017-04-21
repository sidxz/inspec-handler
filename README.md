# Inspec Handler
Use inspec_handler resource to automatically run a set of inspec tests in the client's machine at the last phase of the chef-client run.

# Usage
inspec_handler resource in your cookbook will run the inspec tests for all the recipes that exist in your run list.
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
  log_shift_age         String
  enforced              TrueClass, FalseClass
  whitelist             Array
  blacklist             Array
  environment           Array
  action                Symbol, :hard_run if not specified
end
```
where
* __inspec_handler__ is the resource
* __run_path__ is the dir in which inspec test suites reside. The tests inside this dir is arranged by cookbook-name/recipe-name.rb. recipe-name.rb contains inspec test code for the corresponding recipe.
* __log_path__ is a file where the logs will be stored.
* __log_shift_age__ Number of days for which log files will be kept (default 10). Logs are rotated daily.
* __enforced__ will enforce a rule that enforces each recipe that exists in the runlist to have a corresponding inspec test suite inside run_path. By default, this is set to true. The chef client-run will fail if a missing test suite is detected. Set this to false to revoke the restriction.
* __whitelist__ is a white spaced array, if defined, inspec handler will run test suites for them. This will override the runlist. In other words, inspec handler will only run test suites for the whitelist array. example whitelist %w(cookbook1::default cookbook2::install)
* __blacklist__ is a white spaced array that removes the defined recipes from the test suite array. Tests for these recipes will be skipped from the run list. 
* __environment__ is a white spaced array, when defined will restrict the inspec handler to run only in the defined environments. By default inspec handlers runs in all environment.

# Actions
This resource has the following actions:
```ruby
:hard_run
```
This runs all the defined tests and raises/fails chef client-run (converge) if any of the test fails
```ruby
:soft_run
```
It warns, but does not fail a chef client-run if the inspec tests fail

# Automatic Chef Failure
During a hard run, if tests detect any failure, the handler raises an error to abort the Chef execution. This error can be captured by any other exception handler and be treated like any other error in the Chef execution.

# About
This project was initiated to leverage the power of Inspec to perform smoke and integration test in chef automate's CI/CD pipeline.   
This avoids sharing of ssh keys of privileged users in between runner and client node. The Inspec tests are performed directly on the client node during the chef converge phase.  
In general, this is used in conjunction with the chef-generator-cookbook(https://github.com/sidxz/chef-code-generator) that automatically creates a basic template for these tests.   
Using this generator cookbook, when a cookbook is created using the 'chef generate cookbook' command, it creates a corresponding Inspec test template (for default recipe) placed at templates/default/inspec-tests/default.rb.  
This is repeated when a new recipe is added using the 'chef generate recipe' command.  It also injects some code to the recipes, so as to copy these test files to a specific location to the client node, from where inspec_handler will run these tests. (which is again defined by the run_path property).  
The idea is to run an Inspec test per recipe.  
When this is run together with multiple cookbooks, Inspec Handler parses the run list and sequentially runs these tests.  
Since Inspec test files are created using templates of cookbooks, data bags and chef variables can also be used.  
This provides a good way to perform smoke and integration testing using Inspec in the client node while going through chef automate's CI/CD pipeline, or in general, can be used to automatically test the infrastructure during a client run.  
__NOTE: This cookbook should be placed at the end of your runlist.__


