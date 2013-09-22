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
  module ActionControllerExtension
    def self.included(base)
      base.send(:include, Tr8n::ActionCommonMethods)
      base.send(:include, InstanceMethods)
      base.before_filter  :tr8n_init_request_context
      base.after_filter   :tr8n_reset_request_context
    end

    module InstanceMethods

      def tr8n_browser_accepted_locales
        @tr8n_browser_accepted_locales ||= Tr8n::Utils.browser_accepted_locales(request)
      end

      def tr8n_user_preferred_locale
        @tr8n_user_preferred_locale ||= begin
          tr8n_browser_accepted_locales.each do |locale|
            lang = Tr8n::Language.by_locale(locale)
            return locale if lang and lang.enabled?
          end
          Tr8n::Config.default_locale
        end
      end

      def tr8n_request_remote_ip
        @tr8n_request_remote_ip ||= begin
          if request.env['HTTP_X_FORWARDED_FOR']
            request.env['HTTP_X_FORWARDED_FOR'].split(',').first
          else
            request.remote_ip
          end
        end
      end
      
      def tr8n_source
        @tr8n_source ||= begin
          "/#{controller_name}/#{action_name}"
        rescue
          self.class.name
        end
      end

      def tr8n_component
        nil
      end  

      def tr8n_get_current_locale
        self.send(Tr8n::Config.current_locale_method)
      rescue
        # fallback to the default session based locale implementation
        # choose the first settings from the accepted languages header
        session[:locale] = tr8n_user_preferred_locale unless session[:locale]
        session[:locale] = params[:locale] if params[:locale]
        session[:locale]
      end

      def tr8n_get_current_user
        self.send(Tr8n::Config.current_user_method)
      rescue
        nil
      end

      def tr8n_init_request_context
        return unless Tr8n::Config.enabled?

        # initialize request thread variables
        Tr8n::RequestContext.init(tr8n_get_current_locale, tr8n_get_current_user, tr8n_source, tr8n_component)

        # for logged out users, fallback onto tr8n_access_key
        if Tr8n::RequestContext.current_user_is_guest?
          tr8n_access_key = params[:tr8n_access_key] || session[:tr8n_access_key]
          unless tr8n_access_key.blank?
            Tr8n::RequestContext.set_current_translator(Tr8n::Translator.find_by_access_key(tr8n_access_key))
          end
        end

        # track user's last ip address  
        if Tr8n::Config.enable_country_tracking? and Tr8n::RequestContext.current_user_is_translator?
          Tr8n::RequestContext.current_translator.update_last_ip(tr8n_request_remote_ip)
        end

        # register component and verify that the current user is authorized to view it
        unless Tr8n::RequestContext.current_user_is_authorized_to_view_component?
          trfe("You are not authorized to view this component")
          return redirect_to(Tr8n::Config.default_url)
        end

        unless Tr8n::RequestContext.current_user_is_authorized_to_view_language?
          Tr8n::RequestContext.set_current_language(Tr8n::Config.default_language)
        end
      end

      def tr8n_reset_request_context
        Tr8n::RequestContext.reset
      end

    end
  end
end
