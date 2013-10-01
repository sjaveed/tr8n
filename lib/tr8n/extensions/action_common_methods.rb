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
    # There are three ways to call the tr method
    #
    # tr(label, desc = "", tokens = {}, options = {})
    # or
    # tr(label, tokens = {}, options = {})
    # or
    # tr(:label => label, :description => "", :tokens => {}, :options => {})
    ############################################################
    def tr(label, description = "", tokens = {}, options = {})
      t0 = Time.now
      params = Tr8n::Utils.normalize_tr_params(label, description, tokens, options)

      return params[:label] if params[:label].tr8n_translated?

      params[:options][:caller] = caller

      if request
        params[:options][:url]  = request.url
        params[:options][:host] = request.env['HTTP_HOST']
      end

      if Tr8n::Config.disabled?
        return Tr8n::TranslationKey.substitute_tokens(params[:label], params[:tokens], params[:options])
      end

      translation = Tr8n::RequestContext.current_language.translate(params[:label], params[:description], params[:tokens], params[:options])

      t1 = Time.now
      # Tr8n::Logger.debug("#{label} : (#{t1-t0} mls)")

      return translation
    rescue Tr8n::Exception => ex
      Tr8n::Logger.error("ERROR: #{label}")
      Tr8n::Logger.error(ex.message + "\n=> " + ex.backtrace.join("\n=> "))
      return label
    end

    # for translating labels
    def trl(label, description = "", tokens = {}, options = {})
      params = Tr8n::Utils.normalize_tr_params(label, description, tokens, options)
      params[:options][:skip_decorations] = true
      tr(params)
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
    def tra(label, description = "", tokens = {}, options = {})
      params = Tr8n::Utils.normalize_tr_params(label, description, tokens, options)

      if Tr8n::Config.enable_admin_translations?
        if Tr8n::RequestContext.container_application.feature_enabled?(:admin_translations)
          return tr(params)
        else
          return trl(params)
        end
      end

      Tr8n::Config.default_language.translate(label, description, tokens, options)
    end

    # for admin translations
    def trla(label, description = "", tokens = {}, options = {})
      params = Tr8n::Utils.normalize_tr_params(label, description, tokens, options)
      params[:options][:skip_decorations] = true
      tra(params)
    end

    ######################################################################
    ## Common methods - wrappers
    ## Controllers can override them, if necessary
    ######################################################################

    def tr8n_current_application
      Tr8n::RequestContext.current_application
    end

    def tr8n_current_user
      Tr8n::RequestContext.current_user
    end

    def tr8n_current_language
      Tr8n::RequestContext.current_language
    end

    def tr8n_default_language
      Tr8n::Config.default_language
    end

    def tr8n_current_translator
      Tr8n::RequestContext.current_translator
    end

    def tr8n_current_user_is_translator?
      Tr8n::RequestContext.current_user_is_translator?
    end

    def tr8n_current_user_is_guest?
      Tr8n::RequestContext.current_user_is_guest?
    end

    def tr8n_current_user_is_admin?
      Tr8n::RequestContext.current_user_is_admin?
    end

    def tr8n_current_user_is_manager?
      Tr8n::RequestContext.current_user_is_manager?
    end

  end
end
