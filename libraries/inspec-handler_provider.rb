##
# Author:: Siddhant Rath (<sid@tamu.edu>)
# License:: Apache License, Version 2.0
#
#       http://www.github.com/sidxz/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

require "json"
require "mixlib/shellout"
#require "chef/handler"
#require "chef/run_status"
class Chef
  class Provider
    class InspecHandler < Chef::Provider
      ##
      #
      # This HWRP Provides a way to automatically run a set of inspec tests at the end of chef-client run.
      # /!\ IMPORTANT: This cookbook should be the LAST in your runlist
      #
      ##
      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::InspecHandler.new(new_resource.name)
        @current_resource.run_path(new_resource.run_path)
        @current_resource.log_path(new_resource.log_path)
        @current_resource.enforced(new_resource.enforced)
        @current_resource.whitelist(new_resource.whitelist)
        @current_resource.blacklist(new_resource.blacklist)
      end

      #Action Methods

      def action_hard_run
        run_tests(true)
      end

      def action_soft_run
        run_tests(false)
      end

      def action_disable
      end
    
      #Actions
      def run_tests(raise_on_fail)
        testStack = generate_test_stack
        testStack.each do |t|
          Chef::Log.warn("Running INSPEC:: #{t}")
          cmd = Mixlib::ShellOut.new("inspec exec #{t}", :live_stream => STDOUT)
          cmd.run_command
          if raise_on_fail then cmd.error! end
        end
        ##############EXPERIMENTS####################
        #cookbooks = run_context.parent_run_context
        #cookbooks = run_list.run_list_items
        #cookbooks = run_context.cookbook_collection
        #Chef::Log.warn(cookbooks)
        #Chef::Log.warn("Cookbooks and versions run: #{cookbooks.keys.map {|x| cookbooks[x].name + ' ' + cookbooks[x].version} }")
        #Chef::Log.warn(JSON.pretty_generate(cookbooks))

      end

      #Helper Methods

      def generate_test_stack
        ##
        #
        # This method generates the test stack that will be run by inspec
        # An example of output Stack is ["/etc/chef/inspec-handler/cookbook1/test1.rb, "/etc/chef/inspec-handler/cookbook2/tesxtx.rb"]
        # This stack is created during runtime by parsing the run list so as to run only those tests who have a recipe entry 
        # in the run list. method fetch_test_list does the backend fetching.
        #
        ##
        enforced = current_resource.enforced
        runPath = current_resource.run_path
        testList = fetch_test_list
        Chef::Log.warn(testList)
        testStack = Array.new
        # Check if test files exists for each recipe
        testList.each do |itest|
          #See if file exists
          # enforced => raise error and quit
          # not enforced => by pass in test stack
          if ::File.exists?("#{runPath}/#{itest}.rb") then
            testStack.push("#{runPath}/#{itest}.rb")
          else
            Chef::Log.warn("/!\\ File #{runPath}/#{itest} NOT found")
            if enforced
              # Raise Error and quit
              Chef::Log.warn("/!\\ INSPEC HANDLER TESTING IS ENFORCED. To automatically skip unavailable inspec tests, set enforce to false")
              raise "InspecHandler : Test #{runPath}/#{itest}.rb NOT found. Corresponding recipe is found in run-list!"
            end  
          end
        end
      return testStack
      end
      
      def is_test_kitchen?
        #res = shell_out_compact!("getent", "passwd", "vagrant", returns: [0, 1, 2]).stdout
        res = shell_out_command("getent", "passwd", "vagrant", returns: [0, 1, 2]).stdout
        Chef::Log.warn(res);
        (res == 0)? (return true): (return false);
      end

      def run_noninteractive(*args)
        shell_out_compact!(*args)
      end

      def fetch_test_list()
        ##
        #
        #Check if whitelist is set. If whitelist is enabled, use test cases only for these cookbooks
        #
        ##
        paths = Array.new
        ##--> WHITELIST --<
        if (current_resource.whitelist != nil) then
          current_resource.whitelist.each do |recipe|
            paths.push(convert_recipe_to_path recipe)
          end
          return paths
        end

        ##
        #
        # Parse run list for chef-client or /tmp/chef/dna.json for test-kitchen and build an array of active recipes
        #
        ##
        ##--> TEST KITCHEN --<
        if is_test_kitchen? then
          # To get runlist parse /tmp/chef/dna.json
          Chef::Log.warn("Using Test Kitchen: Will Parse /tmp/chef/dna.json for runlist")
          string = File.read('/tmp/kitchen/dna.json')
          parsed = JSON.parse(string)
          parsed["run_list"].each do |k|
            k.slice!(0,7)       #Remove recipe[
            k = k.chop          #Remove ] 
            k = k.sub("::","/") 
            paths.push(k)
          end
        else

          ##--> CHEF-CLIENT <--
          # Will use node.runlist
          node.run_list.recipe_names.each do |recipe|
              paths.push(convert_recipe_to_path recipe)
          end
        end
        
        ##
        #
        # Remove Blacklisted items from runlist
        #
        ##
        if current_resource.blacklist != nil then
          current_resource.blacklist.each do |blacklisted_recipe|
            if paths.include? convert_recipe_to_path blacklisted_recipe then paths.delete(convert_recipe_to_path blacklisted_recipe) end
          end
        end

        ##
        #
        #Remove inspec handler cookbook from test list
        #
        ##
        if paths.include? "inspec_handler/default" then paths.delete("inspec_handler/default") end
        return paths
      end

      def convert_recipe_to_path(recipe)
        if !recipe.include? "::" then
          return (recipe+"/"+"default")
        else
          return (recipe.sub("::","/"))
        end
      end

    end
  end
end

