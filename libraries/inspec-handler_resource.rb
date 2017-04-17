require 'chef/resource'
class Chef
  class Resource
    class InspecHandler < Chef::Resource

      provides :inspec_handler , :on_platforms => :all

     def initialize(name, run_context=nil)
       super
       @resource_name = :inspec_handler
       @allowed_actions = [:hard_run, :soft_run]
       @action = :hard_run

       #resource defaults
       @name = name;
       @run_path = "/etc/chef/inspec-tests"
       @log_path = "/var/logs/inspec-handler.log"
       @enforced = true
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

    end
  end
end 
