##
## Author:: Siddhant Rath (<sid@tamu.edu>)
## License:: Apache License, Version 2.0
##
##       http://www.github.com/sidxz/
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
###


require 'chef/resource'
class Chef
  class Resource
    class InspecHandler < Chef::Resource

      #provides :inspec_handler , :on_platforms => :all
      provides :inspec_handler

     def initialize(name, run_context=nil)
       super
       ##
       # actions : 
       # Hard Run will fail the chef-run if any of the inspec tests fail
       # Soft Run will continue with the chef run by displaying warnings
       ## 
       @resource_name = :inspec_handler
       @allowed_actions = [:hard_run, :soft_run, :nothing]
       @action = :hard_run

       ##
       #
       #run_path : Directory in the client node where inspec tests are placed
       #           Tests must be arranged in <cookbook_name>/<recipe_name>.rb inside run path dir
       #log_path : dir in which logs will be generated
       #enforced : Enforces a restriction binding a compulsary test for each recipe that exists in runlist.
       #           In other words, All recipes that exists in the client run list must have a corresponding test
       #           in <run_path>/<cookbookname>/<recipe_name>.rb. If this file is missing, it will result in a run time fail.
       #whitelist: Overide runlist and run tests for recipes defined in this array
       #blacklist: Remove these tests from runlist
       #test_environment : If defined will restrict the inspec handler to run only in the defined test environments.
       #production_environment : defines your production environment in which inspec_handler will run only if there
       #           is a change in the runlist. If this is not set, all the inspec_tests are run on each chef-client run.
       #track_attributes : Look for changes in attributes to trigger tests in production environment.
       #abort_on_fail : Will skip further tests if one of the test fails
       #
       ##

       #resource defaults
       @name = name;
       @run_path = "/etc/chef/inspec-tests"
       @log_path = "/var/log/inspec_handler"
       @log_shift_age = 10
       @enforced = true
       @production_environment = nil
       @abort_on_fail = true
       @track_attributes = true
     end

     #Methods to get and set attributes
     def name(arg=nil)
       set_or_return(:name, arg, :kind_of => String)
     end

     def run_path(arg=nil)
       set_or_return(:run_path, arg, :kind_of => String)
     end

     def log_path(arg=nil)
       set_or_return(:log_path, arg, :kind_of => String)
     end

     def enforced(arg=nil)
       set_or_return(:enforced, arg, :kind_of => [TrueClass, FalseClass])
     end

     def whitelist(arg=nil)
       set_or_return(:whitelist, arg, :kind_of => Array)
     end

     def blacklist(arg=nil)
       set_or_return(:blacklist, arg, :kind_of => Array)
     end

     def test_environment(arg=nil)
       set_or_return(:test_environment, arg, :kind_of => Array)
     end

     def log_shift_age(arg=nil)
       set_or_return(:log_shift_age, arg, :kind_of => String)
     end

     def production_environment(arg=nil)
       set_or_return(:production_environment, arg, :kind_of => String)
     end

     def abort_on_fail(arg=nil)
       set_or_return(:abort_on_fail, arg, :kind_of => [TrueClass, FalseClass])
     end

     def track_attributes(arg=nil)
       set_or_return(:track_attributes, arg, :kind_of => [TrueClass, FalseClass])
     end

    end
  end
end 
