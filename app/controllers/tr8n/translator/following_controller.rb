#--
# Copyright (c) 2010-2013 Michael Berkovich, tr8nhub.com
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

class Tr8n::Translator::FollowingController < Tr8n::Translator::BaseController

  def index
    @translator = Tr8n::RequestContext.current_translator
    @translators = Tr8n::TranslatorFollowing.where("translator_id = ? and object_type = ?", tr8n_current_translator.id, "Tr8n::Translator").collect{|f| f.object}
    @translation_keys = Tr8n::TranslatorFollowing.where("translator_id = ? and object_type = ?", tr8n_current_translator.id, "Tr8n::TranslationKey").collect{|f| f.object}
  end

  def follow
    if params[:translation_key_id]
      object = Tr8n::TranslationKey.find_by_id(params[:translation_key_id])
      trfn("You are now following this translation key") if object
    elsif params[:translator_id]
      object = Tr8n::Translator.find_by_id(params[:translator_id])
      trfn("You are now following {dashboard}", nil, :translator => object ) if object
    end

    if object
      tr8n_current_translator.follow(object)
    end

    redirect_to_source
  end

  def unfollow
    if params[:translation_key_id]
      object = Tr8n::TranslationKey.find_by_id(params[:translation_key_id])
    elsif params[:translator_id]
      object = Tr8n::Translator.find_by_id(params[:translator_id])
    end

    tr8n_current_translator.unfollow(object) if object
    redirect_to_source
  end

  def lb_report
    if request.post?
      @reported_object = params[:object_type].constantize.find(params[:object_id])
      Tr8n::TranslatorReport.submit(Tr8n::RequestContext.current_translator, @reported_object, params[:reason], params[:comment])
      trfn("Thank you for submitting your report.")
      return dismiss_lightbox
    end

    if params[:translation_key_id]
      @reported_object = Tr8n::TranslationKey.find_by_id(params[:translation_key_id])
    elsif params[:translation_id]
      @reported_object = Tr8n::Translation.find_by_id(params[:translation_id])
    elsif params[:message_id]
      @reported_object = Tr8n::Forum::Message.find_by_id(params[:message_id])
    elsif params[:comment_id]
      @reported_object = Tr8n::TranslationKeyComment.find_by_id(params[:comment_id])
    end
    render :layout => false
  end



end