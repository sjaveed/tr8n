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
  class RequestContext

    # all variables must be registered as Thread safe variable
    # and must be cleared at the end of each request
    def self.init(locale, user = nil, source = nil, component = nil)
      set_current_language(Tr8n::Language.by_locale(locale))
      set_current_user(user)
      set_current_translator(Tr8n::Translator.by_user(user))
      set_current_source(source)  #keep it as string until it is needed

      # register source with component
      unless component.nil?
        set_current_component(component)
        current_component.add_source(current_source)
      end

      Thread.current[:tr8n_block_options]      = []
    end

    def self.container_application
      Thread.current[:tr8n_container_application] ||= Tr8n::Application.find_by_key("default")
    end

    def self.reset_container_application
      Thread.current[:tr8n_container_application] = nil
    end

    def self.current_user
      Thread.current[:tr8n_user]
    end

    def self.set_current_user(user)
      Thread.current[:tr8n_user] = user
    end

    def self.current_source
      Thread.current[:tr8n_source]
    end

    def self.set_current_source(source)
      # TODO: we should only register sources when keys are present
      source = Tr8n::TranslationSource.find_or_create(source) if source.is_a?(String)
      Thread.current[:tr8n_source] = source
    end

    def self.current_component
      Thread.current[:tr8n_component]
    end

    def self.set_current_component(component)
      component = Tr8n::Component.find_or_create(component) if component.is_a?(String)
      Thread.current[:tr8n_component] = component
    end

    def self.current_language
      Thread.current[:tr8n_language] ||= Tr8n::Config.default_language
    end

    def self.set_current_language(language)
      language = Tr8n::Language.by_locale(language) if language.is_a?(String)
      Thread.current[:tr8n_language] = language
    end

    def self.current_user_is_translator?
      Thread.current[:tr8n_translator] != nil
    end

    def self.current_user_is_authorized_to_view_component?(component = current_component)
      return true if component.nil?

      component = Tr8n::Component.find_by_key(component.to_s) if component.is_a?(Symbol) or component.is_a?(String)

      return true unless component.restricted?
      return false unless current_user_is_translator?
      return true if component.translator_authorized?

      if current_user_is_admin?
        Tr8n::ComponentTranslator.find_or_create(component, current_translator)
        return true
      end

      false
    end

    def self.current_user_is_authorized_to_view_language?(component = current_component, language = current_language)
      return true if component.nil? # no component present, so be it

      component = Tr8n::Component.find_by_key(component.to_s) if component.is_a?(Symbol) or component.is_a?(String)

      if current_user_is_translator?
        return true if component.translators.include?(current_translator)
      end

      component.component_languages.each do |cl|
        return cl.live? if cl.language_id == language.id
      end

      true
    end

    def self.current_translator
      Thread.current[:tr8n_translator]
    end

    def self.set_current_translator(translator)
      Thread.current[:tr8n_translator]  = translator
    end

    def self.format
      Thread.current[:tr8n_format] ||= 'html'
    end

    def self.set_format(request_format)
      Thread.current[:tr8n_format] = request_format
    end

    def self.decoration_tokens
      Tr8n::Config.default_decoration_tokens[format].merge(current_application.tokens("decoration"))
    end

    def self.data_tokens
      Tr8n::Config.default_data_tokens[format].merge(current_application.tokens("data"))
    end

    def self.current_user_is_admin?
      Tr8n::Config.admin_user?(current_user)
    end

    def self.current_user_is_manager?
      return false unless current_user_is_translator?
      return true if current_user_is_admin?
      current_translator.manager?
    end

    def self.current_user_is_guest?
      Tr8n::Config.guest_user?(current_user)
    end

    def self.remote_application
      Thread.current[:tr8n_remote_application]
    end

    def self.set_remote_application(application)
      application = Tr8n::Application.by_key(application) if application.is_a?(String)
      Thread.current[:tr8n_remote_application] = application
    end

    def self.current_application
      remote_application || container_application
    end

    def self.signed_request_name
      "tr8n_#{remote_application.key}"
    end

    def self.signed_request_body
      params = {
          'locale'  => current_language.locale,
      }

      if current_user_is_translator?
        request_token = remote_application.find_or_create_request_token(current_translator)
        params.merge!({
          'code' => request_token.token,
          'translator' => {
            'id'      => current_translator.id,
            'email'   => current_translator.email,
            'name'    => current_translator.name,
            'inline'  => current_translator.inline_mode,
            'manager' => current_translator.manager?,
          }
        })
      end

      Tr8n::Utils.sign_and_encode_params(params, remote_application.secret)
    end

    #########################################################
    ### BLOCK OPTIONS
    #########################################################
    def self.block_options
      (Thread.current[:tr8n_block_options] || []).last || {}
    end

    def self.current_source_from_block_options
      arr = Thread.current[:tr8n_block_options] || []
      arr.reverse.each do |opts|
        return Tr8n::TranslationSource.find_or_create(opts[:source]) unless opts[:source].blank?
      end
      nil
    end

    def self.current_component_from_block_options
      arr = Thread.current[:tr8n_block_options] || []
      arr.reverse.each do |opts|
        return Tr8n::Component.find_or_create(opts[:component]) unless opts[:component].blank?
      end
      current_component
    end

    def self.default_locale
      return block_options[:default_locale] if block_options[:default_locale]
      Tr8n::Config.default_locale
    end

    def self.default_admin_locale
      return block_options[:default_admin_locale] if block_options[:default_admin_locale]
      Tr8n::Config.default_admin_locale
    end

    #########################################################
    # Rendering Email Templates
    #########################################################

    def self.render_email_with_options(opts)
      Thread.current[:tr8n_email_render_options] = opts
      if block_given?
        yield
      end
      Thread.current[:tr8n_email_render_options] = {}
    end

    def self.email_render_options
      Thread.current[:tr8n_email_render_options]
    end

    def self.reset
      Thread.current[:tr8n_container_application] = nil
      Thread.current[:tr8n_language]  = nil
      Thread.current[:tr8n_user] = nil
      Thread.current[:tr8n_translator] = nil
      Thread.current[:tr8n_block_options]  = nil
      Thread.current[:tr8n_source] = nil
      Thread.current[:tr8n_component] = nil
      Thread.current[:tr8n_remote_application] = nil
      Thread.current[:tr8n_format] = nil
      Thread.current[:tr8n_email_render_options] = nil
    end
  end
end
