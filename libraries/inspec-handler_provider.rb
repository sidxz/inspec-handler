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


    end
  end
end

