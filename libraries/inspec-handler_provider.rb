require "json"
class Chef
  class Provider
    class InspecHandler < Chef::Provider

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::InspecHandler.new(new_resource.name)
        @current_resource.run_path(new_resource.run_path)
        @current_resource.log_path(new_resource.log_path)
      end

      #Action Methods

      def action_run
      end

      def action_enable
      end

      def action_disable
      end


      #Helper Methods
      def is_test_kitchen?
        res = shell_out_compact!("getent", "passwd", "vagrant", returns[0, 1, 2]).stdout
        Chef::Log.warn(res);
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
        return path
      end

    end
  end
end

