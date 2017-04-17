require "json"
require "mixlib/shellout"
class Chef
  class Provider
    class InspecHandler < Chef::Provider
     include Chef::Mixin::ShellOut 
      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::InspecHandler.new(new_resource.name)
        @current_resource.run_path(new_resource.run_path)
        @current_resource.log_path(new_resource.log_path)
        @current_resource.enforced(new_resource.enforced)
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
          Chef::Log.warn("TEST INSPEC:: #{t}")
          if raise_on_fail then
             shell_out!("inspec", "exec", t,  :live_stream => STDOUT)
          else
             shell_out("inspec", "exec", t,  :live_stream => STDOUT)
          end 
        end
      end

      #Helper Methods

      def generate_test_stack
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
            if enforced
              # Raise Error and quit
              Chef::Log.warn("/!\\ INSPEC HANDLER TESTING IS ENFORCED. To automatically skip unavailable inspec tests, set enforce to false")
              #Chef::Application.fatal!("Test #{runPath}/#{itest}.rb NOT found")
              raise "InspecHandler : Test #{runPath}/#{itest}.rb NOT found. Corresponding recipe is found in run-list!"
            end  
          end
        end
      return testStack
      end
      
      def is_test_kitchen?
        #res = shell_out_compact!("getent", "passwd", "vagrant", returns: [0, 1, 2]).stdout
        #res = shell_out_compact!("getent", "passwd", "vagrant").stdout
        res = shell_out_command("getent", "passwd", "vagrant", returns: [0, 1, 2]).stdout
        Chef::Log.warn(res);
        (res == 0)? (return true): (return false);
      end

      def run_noninteractive(*args)
        shell_out_compact!(*args)
      end

      def fetch_test_list()
        paths = Array.new
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
          # Will use node.runlist
          node.run_list.recipe_names.each do |k|
            if !k.include? "::" then
              paths.push(k+"/"+"default.rb")
            else
              paths.push(k.sub("::","/"))
            end
          end
        end
        return paths
      end

    end
  end
end

