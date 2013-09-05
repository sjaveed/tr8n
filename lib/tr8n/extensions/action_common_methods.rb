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
  module ActionCommonMethods
    ############################################################
    # There are two ways to call the tr method
    #
    # tr(label, desc = "", tokens = {}, options = {})
    # or
    # tr(label, tokens = {}, options = {})
    ############################################################
    def tr(label, desc = "", tokens = {}, options = {})
      return label if label.tr8n_translated?

      if desc.is_a?(Hash)
        options = tokens
        tokens = desc
        desc = ""
      end

      options.merge!(:caller => caller)

      if request
        options.merge!(:url => request.url)
        options.merge!(:host => request.env['HTTP_HOST'])
      end

      unless Tr8n::Config.enabled?
        return Tr8n::TranslationKey.substitute_tokens(label, tokens, options)
      end

      Tr8n::Config.current_language.translate(label, desc, tokens, options)
    end

    # for translating labels
    def trl(label, desc = "", tokens = {}, options = {})
      tr(label, desc, tokens, options.merge(:skip_decorations => true))
    end

    # flash notice
    def trfn(label, desc = "", tokens = {}, options = {})
      flash[:trfn] = tr(label, desc, tokens, options)
    end

    # flash error
    def trfe(label, desc = "", tokens = {}, options = {})
      flash[:trfe] = tr(label, desc, tokens, options)
    end

    # flash warning
    def trfw(label, desc = "", tokens = {}, options = {})
      flash[:trfw] = tr(label, desc, tokens, options)
    end

    # for admin translations
    def tra(label, desc = "", tokens = {}, options = {})
      if desc.is_a?(Hash)
        options = tokens
        tokens = desc
        desc = ""
      end

      if Tr8n::Config.enable_admin_translations?
        return tr(label, desc, tokens, options) if Tr8n::Config.enable_admin_inline_mode?
        return trl(label, desc, tokens, options)
      end
      Tr8n::Config.default_language.translate(label, desc, tokens, options)
    end

    # for admin translations
    def trla(label, desc = "", tokens = {}, options = {})
      tra(label, desc, tokens, options.merge(:skip_decorations => true))
    end

    def tr8n_request_remote_ip
      @remote_ip ||= request.env['HTTP_X_FORWARDED_FOR'] ? request.env['HTTP_X_FORWARDED_FOR'].split(',').first : request.remote_ip
    end

    ######################################################################
    ## Common methods - wrappers
    ######################################################################

    def tr8n_application
      Tr8n::Config.application
    end

    def tr8n_current_application
      Tr8n::Config.current_application
    end

    def tr8n_current_user
      Tr8n::Config.current_user
    end

    def tr8n_current_language
      Tr8n::Config.current_language
    end

    def tr8n_default_language
      Tr8n::Config.default_language
    end

    def tr8n_current_translator
      Tr8n::Config.current_translator
    end

    def tr8n_current_user_is_translator?
      Tr8n::Config.current_user_is_translator?
    end

    def tr8n_current_user_is_guest?
      Tr8n::Config.current_user_is_guest?
    end

    def tr8n_current_user_is_admin?
      Tr8n::Config.current_user_is_admin?
    end

    def tr8n_current_user_is_manager?
      return true if tr8n_current_user_is_admin?
      return false unless tr8n_current_user_is_translator?
      tr8n_current_translator.manager?
    end

  end
end
