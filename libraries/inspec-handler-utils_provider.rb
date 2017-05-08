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
    class InspecHandlerUtils < Chef::Provider
      ##
      #
      # This HWRP Provides a way to automatically run a set of inspec tests at the end of chef-client run.
      # /!\ IMPORTANT: This cookbook should be the LAST in your runlist
      #
      ##
      provides :inspec_handler_utils
      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::InspecHandlerUtils.new(new_resource.name)
        @current_resource.ensure_last(new_resource.ensure_last)
        _string_builder()
      end

      ####################################################################################
      # STRINGS
      ####################################################################################
      def _string_builder()
        # C O R E
        @_string_mod_name = "[Inspec Handler Utils]"
        @_string_warning = "[/!\\]"
        @_string_fail = "[--FAIL--]"
        @_string_fatal = "[--FATAL--]"
        @_string_focus = "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

        #is_at_end
        @_string_is_at_end_skip = "Skipping property ensure_last. To make sure this cookbook runs last, set ensure_last to true "
        @_string_is_at_end_error = "#{cookbook_name} is NOT placed at the end of your runlist. Make sure this cookbook runs last."
        @_string_is_at_end_name_of_wrapper = "inspec_handler::default is expected to be wrapped in #{cookbook_name}"
      end

      ####################################################################################
      #Action Methods
      ####################################################################################

      def action_hard
        utils(true)
      end

      def action_soft
        utils(false)
      end

      ####################################################################################
      #Actions
      ####################################################################################
      def utils(raise_on_fail)

        if @current_resource.ensure_last 
          is_at_end? (raise_on_fail)
        else
          Chef::Log.warn("#{@_string_mod_name} #{@_string_warning} #{@_string_is_at_end_skip}")
        end
        
      end

      def is_at_end? (raise_on_fail)
        Chef::Log.warn("#{@_string_mod_name} #{@_string_warning} #{@_string_is_at_end_name_of_wrapper}")
        if !node["expanded_run_list"].last.include? cookbook_name
          if raise_on_fail then raise "#{@_string_mod_name} #{@_string_fatal}\n#{@_string_focus}\n#{@_string_focus}\n@ #{@_string_is_at_end_error} @\n#{@_string_focus}\n#{@_string_focus}" end
          if !raise_on_fail then Chef::Log.warn("#{@_string_mod_name} #{@_string_warning} #{@_string_is_at_end_error}") end
        end
        return true
      end

    end
  end
end

