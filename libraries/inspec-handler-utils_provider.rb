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
        @current_resource.ensure_last_cookbook(new_resource.ensure_last_cookbook)
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
      end

      ####################################################################################
      #Action Methods
      ####################################################################################

      def action_hard_run
        utils(true)
      end

      def action_soft_run
        utils(false)
      end

      ####################################################################################
      #Actions
      ####################################################################################
      def utils(raise_on_fail)
      is_at_end?
        
      end

      def is_at_end?
        Chef::Log.warn("NAME OF COOKBOOK : #{cookbook_name}")
        return true
      end

    end
  end
end

