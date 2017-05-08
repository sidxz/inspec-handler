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
    class InspecHandlerUtils < Chef::Resource

      #provides :inspec_handler , :on_platforms => :all
      provides :inspec_handler_utils

     def initialize(name, run_context=nil)
       super
       ##
       # actions : 
       # Hard Run will fail the chef-run if any of the inspec tests fail
       # Soft Run will continue with the chef run by displaying warnings
       ## 
       @resource_name = :inspec_handler_utils
       @allowed_actions = [:hard, :soft]
       @action = :hard

       ##
       # ensure_last : ensure that this is the last thing in the runlist
       ##

       #resource defaults
       @name = name;
       @ensure_last = false 
     end

     def name(arg=nil)
       set_or_return(:name, arg, :kind_of => String)
     end

     def ensure_last(arg=nil)
       set_or_return(:ensure_last, arg, :kind_of => [TrueClass, FalseClass])
     end

    end
  end
end 
