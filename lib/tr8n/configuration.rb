#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Tr8n
  class Configuration
    attr_accessor :enable_software_keyboard

    def initialize
      self.enable_software_keyboard = true
      self.enable_keyboard_shortcuts = true

      #self.default_shortcuts =
    end

    #def self.default_shortcuts
    #  @default_shortcuts ||= load_yml("/config/tr8n/site/shortcuts.yml", nil)
    #end
    #
    #def self.enable_inline_translations?
    #  config[:enable_inline_translations]
    #end
    #
    #def self.enable_language_cases?
    #  config[:enable_language_cases]
    #end
    #
    #def self.enable_key_caller_tracking?
    #  config[:enable_key_caller_tracking]
    #end
    #
    #def self.enable_google_suggestions?
    #  config[:enable_google_suggestions]
    #end
    #
    #def self.google_api_key
    #  config[:google_api_key]
    #end
    #
    #def self.enable_glossary_hints?
    #  config[:enable_glossary_hints]
    #end
    #
    #def self.enable_dictionary_lookup?
    #  config[:enable_dictionary_lookup]
    #end
    #
    #def self.enable_language_flags?
    #  config[:enable_language_flags]
    #end
    #
    #def self.enable_language_stats?
    #  config[:enable_language_stats]
    #end
    #
    #def self.open_registration_mode?
    #  config[:open_registration_mode]
    #end
    #
    #def self.enable_registration_disclaimer?
    #  config[:enable_registration_disclaimer]
    #end
    #
    #def self.registration_disclaimer_path
    #  config[:registration_disclaimer_path] || "/tr8n/common/terms_of_service"
    #end
    #
    #def self.enable_fallback_languages?
    #  config[:enable_fallback_languages]
    #end
    #
    #def self.enable_translator_language?
    #  config[:enable_translator_language]
    #end
    #
    #def self.enable_admin_translations?
    #  config[:enable_admin_translations]
    #end
    #
    #def self.enable_admin_inline_mode?
    #  config[:enable_admin_inline_mode]
    #end
    #
    #def self.enable_country_tracking?
    #  config[:enable_country_tracking]
    #end
    #
    #def self.enable_relationships?
    #  config[:enable_relationships]
    #end
    #
    #def self.enable_translator_tabs?
    #  config[:enable_translator_tabs]
    #end
    #
    #def self.offline_task_method
    #  config[:offline_task_method]
    #end
  end
end

