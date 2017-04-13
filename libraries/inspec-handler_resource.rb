class Chef
  class Resource
    class InspecHandler < Chef::Resource

      provides :inspec-handler, :on_platforms => :all

     def initialize(name, run_context=nil)
       super
       @resource_name = :inspec-handler
       @allowed_actions = [:run, :enable, :disable]
       @action = :run

       #resource defaults
       @name = name;
       @run_path = "/etc/chef/inspec-tests/"
       @log_path = "/var/logs/inspec-handler.log"
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

    end
  end
end 
