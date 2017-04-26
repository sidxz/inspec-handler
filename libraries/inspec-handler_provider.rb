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
require "logger"
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
      provides :inspec_handler
      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::InspecHandler.new(new_resource.name)
        @current_resource.run_path(new_resource.run_path)
        @current_resource.log_path(new_resource.log_path)
        @current_resource.log_shift_age(new_resource.log_shift_age)
        @current_resource.enforced(new_resource.enforced)
        @current_resource.whitelist(new_resource.whitelist)
        @current_resource.blacklist(new_resource.blacklist)
        @current_resource.environment(new_resource.environment)
        @current_resource.production_environment(new_resource.production_environment)
      end                       

      ####################################################################################
      #Action Methods
      ####################################################################################

      def action_hard_run
        run_tests(true)
      end

      def action_soft_run
        run_tests(false)
      end

      def action_disable
      end
    
      ####################################################################################
      #Actions
      ####################################################################################
      def run_tests(raise_on_fail)

        ##
        #
        # Generate Test Stack
        #
        ##
        testStack = generate_test_stack

        ##
        #
        # Filters
        # 
        ##
        if node.environment == current_resource.production_environment then
          if !run_at_prod? testStack then
            Chef::Log.warn("Inspec Handler Skipped Tests due to Production Environment Filter. Environment: #{node.chef_environment}. There is No change in runlist")
           return true 
         end
        else
          if block_filter_env? then
            Chef::Log.warn("Inspec Handler Skipped Tests due to Environment Filter. Environment: #{node.chef_environment}")
            return true 
          end
        end
        
        ##
        #
        # Execute inspec tests
        #
        ### 
        
        testStack.each do |t|
          Chef::Log.warn("Running INSPEC:: #{t}")
          cmd = Mixlib::ShellOut.new("inspec exec #{t}", :live_stream => STDOUT)
          cmd.run_command
          if cmd.error? then generate_log cmd end
          if raise_on_fail then cmd.error! end
        end

      end


      ######################################################################################  
      #Helper Methods
      ######################################################################################
      def generate_test_stack
        ##
        #
        # This method generates the test stack that will be run by inspec
        # An example of output Stack is ["/etc/chef/inspec-handler/cookbook1/test1.rb, "/etc/chef/inspec-handler/cookbook2/tesxtx.rb"]
        # This stack is created during runtime by parsing the run list so as to run only those tests who have a recipe entry 
        # in the run list. method fetch_test_list does the backend fetching.
        #
        # /!\ Might RAISE if test file is not present 
        ##
        enforced = current_resource.enforced
        runPath = current_resource.run_path
        testList = fetch_test_list
        testStack = Array.new

        testList.each do |itest|
          ##
          #
          # See if file exists
          # enforced => raise error and quit
          # not enforced => by pass in test stack
          #
          ##
          if ::File.exists?("#{runPath}/#{itest}.rb") then
            testStack.push("#{runPath}/#{itest}.rb")
          else
            Chef::Log.warn("/!\\ File #{runPath}/#{itest} NOT found")
            if enforced
              # Raise and quit
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
          node["expanded_run_list"].each do |recipe|
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

      ##
      #
      # LOGGING
      #
      ##
      def generate_log(message)
        ::FileUtils.mkdir_p(current_resource.log_path) unless ::File.directory?(current_resource.log_path)
        logger = Logger.new("#{current_resource.log_path}/error.log", current_resource.log_shift_age.to_i, 'daily')
        logger.error (message)
        logger.close
      end

      ##
      #
      #Production restriction: Will run the test only if there is a change in run list
      #
      ##
      def diff_run_list?(testStack)
        ::FileUtils.mkdir_p("/var/lib/inspec_handler/cache/") unless ::File.directory?("/var/lib/inspec_handler/cache/")
        cache = ::File.open("/var/lib/inspec_handler/cache/runlist", ::File::RDWR | ::File::CREAT, 750)
        cache_content = cache.read
        cookbooks = run_context.cookbook_collection
        gen_runlist = "#{cookbooks.keys.map {|x| cookbooks[x].name + ' ' + cookbooks[x].version}} #{testStack.to_s}"
        if !gen_runlist.eql? cache_content then 
          cache.close
          cache = ::File.open("/var/lib/inspec_handler/cache/runlist", ::File::RDWR | ::File::TRUNC | ::File::CREAT, 750)
          cache.write(gen_runlist)
          Chef::Log.warn("/!\\ Change in Runlist Detected")
          cache.close
          return true
        else
          return false
        end
      end

      ##
      #
      # FILTERS
      #
      ##
      def block_filter_env?
        if ((current_resource.environment != nil) && (!current_resource.environment.include? node.chef_environment))
            return true
          else
            return false
          end
      end

      def run_at_prod?(testStack)
        if ((current_resource.production_environment != nil) && (node.chef_environment == current_resource.production_environment) && (diff_run_list?(testStack)))
            return true
          else
            return false
          end
      end




    end
  end
end

