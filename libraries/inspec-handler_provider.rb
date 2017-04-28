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
        @current_resource.test_environment(new_resource.test_environment)
        @current_resource.production_environment(new_resource.production_environment)
        @current_resource.abort_on_fail(new_resource.abort_on_fail)
        _string_builder()
      end

      ####################################################################################
      # STRINGS
      ####################################################################################
      def _string_builder()
        # C O R E
        @_string_mod_name = "[Inspec Handler]"
        @_string_warning = "[/!\\]"
        @_string_fail = "[--FAIL--]"
        @_string_fatal = "[--FATAL--]"

        # Funcrion run_tests
        @_string_production_filter = "[No Change in RunList] Filter: Production Environment is set. Skipping Tests. "
        @_string_test_env_filter   = "[#{node.chef_environment} not in test environment set] Filter : Test Environment is set. Skipping Tests "
        @_string_start_time = "[Testing Started At #{Time.new.strftime('%c')}] "
        @_string_rescue_on_abort = "Further testing has been aborted. To change this behavior, modify property 'abort_on_fail' to false."
        #Function generate_test_stack
        @_string_file_not_found = "[File Not Found] "
        @_string_enforced_warning = "[Testing is Enforced] To skip unavailable tests, set property 'enforce' to false"
        @_string_enforced_raise = "[Test Not Found] Recipe is present in runlist. Expected test file to be at "
        #Function is_test_kitchen?
        @_string_kitchen = "[Test Kitchen Detected] Will parse /tmp/chef/dna.json to create runlist"
        #Function diff_run_list?
        @_string_diff_run_list = "[Runlist Changed] Runlist has been modified or a cookbook has changed its version."
        #Function run_at_prod?
        @_string_last_fail ="[Fail detected in last run] Will Override Production Filter "
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
            Chef::Log.warn("#{@_string_mod_name} #{@_string_production_filter}")
           return true 
         end
        else
          if block_filter_env? then
            Chef::Log.warn("#{@_string_mod_name} #{@_string_test_env_filter}")
            return true 
          end
        end
        
        ##
        #
        # Execute inspec tests
        #
        ### 
        abort_on_fail = current_resource.abort_on_fail
        
        # Set local var has_error = false
        has_error = false

        # Variable to hold log string
        error_log = "#{@_string_mod_name} #{@_string_start_time}"
        
        begin
          testStack.each do |t|
            Chef::Log.warn("#{@_string_mod_name} Running INSPEC:: #{t}")
            cmd = Mixlib::ShellOut.new("inspec exec #{t}", :live_stream => STDOUT)
            cmd.run_command
           
            if cmd.error? then has_error = true; error_log << cmd.stdout  end
            if (abort_on_fail && has_error) then raise "Aborted" end
          end
        rescue
            Chef::Log.warn("#{@_string_mod_name} #{@_string_fail} #{@_string_rescue_on_abort}")
        else
        # If run suceeds at prod set 'inspec_handler_last_success' to true
            if (is_at_prod?) then node.normal['inspec_handler_last_success'] = true end
        ensure
          if (has_error) then generate_log error_log end
          if (raise_on_fail && has_error) then raise error_log end
          if (is_at_prod? && has_error) then node.normal['inspec_handler_last_success'] = false end
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
            Chef::Log.warn("#{@_string_mod_name} #{@_string_warning} #{@_string_file_not_found} #{runPath}/#{itest} ")
            if enforced
              # Raise and quit
              Chef::Log.warn("#{@_string_mod_name} #{@_string_enforced_warning}")
              raise "#{@_string_mod_name} #{@_string_fatal} #{@_string_enforced_raise} #{runPath}/#{itest}.rb"
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
          Chef::Log.warn("#{@_string_mod_name} #{@_string_kitchen}")
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
        ##
        #
        # Rotating Log Files
        #
        ##
        ::FileUtils.mkdir_p(current_resource.log_path) unless ::File.directory?(current_resource.log_path)
        logger = ::Logger.new("#{current_resource.log_path}/#{current_resource.name.downcase.tr(' ', '_')}_error.log", 'daily', current_resource.log_shift_age.to_i)
        ::File.chmod(0440, "#{current_resource.log_path}/#{current_resource.name.downcase.tr(' ', '_')}_error.log")
        logger.error (message)
        logger.close
        ##
        #
        # Record last failure in a separate file
        #
        ##
        last_run_with_error = ::File.open("#{current_resource.log_path}/#{current_resource.name.downcase.tr(' ', '_')}_last_error.log", ::File::RDWR | ::File::TRUNC | ::File::CREAT, 0440)
        last_run_with_error.write(message)
        last_run_with_error.close
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
          Chef::Log.warn("#{@_string_mod_name} #{@_string_diff_run_list}")
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
        if ((current_resource.test_environment != nil) && (!current_resource.test_environment.include? node.chef_environment))
            return true
          else
            return false
          end
      end

      def run_at_prod?(testStack)
        # Check if node attribute is set
        if !node.attribute?('inspec_handler_last_success')
          node.normal['inspec_handler_last_success'] = false;
        end
        
        if (is_at_prod? && node.normal['inspec_handler_last_success'] == false)
          Chef::Log.warn("#{@_string_mod_name} #{@_string_warning} #{@_string_last_fail}")
        end
        if ((is_at_prod?) && ((node.normal['inspec_handler_last_success'] == false) || (diff_run_list?(testStack))))
            return true
          else
            return false
          end
      end

      def is_at_prod?
        if ((current_resource.production_environment != nil) && (node.chef_environment == current_resource.production_environment))
          return true
        else
          return false
        end
      end

    end
  end
end

