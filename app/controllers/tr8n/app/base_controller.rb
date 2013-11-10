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

class Tr8n::App::BaseController < Tr8n::BaseController


private

  def date_options
    @date_options ||=  begin
      [
        ["on any date", "any"],
        ["today", "today"],
        ["yesterday", "yesterday"],
        ["in the last week", "last_week"],
        ["in the last month", "last_month"]
      ].collect{|option| [option.first.trl("Date option"), option.last]}
    end
  end
  helper_method :date_options

  def language_options
    @language_options ||= begin
      langs = tr8n_selected_application.languages.collect{|lang| [lang.english_name, lang.id.to_s]}
      langs.unshift([tra("all languages"), ""])
      langs
    end
  end
  helper_method :language_options

  def translator_options
    @translator_options ||= begin
      opts = []
      opts << ["by anyone", "anyone"]
      opts << ["by me", "me"]
      tr8n_selected_application.translators.each do |t|
        next if tr8n_current_translator == t
        opts << ["by #{t.name}", t.id]
      end
      opts
    end
  end
  helper_method :translator_options

  def translation_status_options
    @translation_status_options ||= begin
      [
        ["all translations", "all"],
        ["accepted", "accepted"],
        ["pending", "pending"],
        ["rejected", "rejected"]
      ].collect{|option| [option.first.trl("Translation status"), option.last]}
    end
  end
  helper_method :translation_status_options

  def validate_application_management
    # admins can do everything
    return if tr8n_current_user_is_admin?

    unless application_manager?
      return redirect_to(:controller => "/tr8n/app/phrases", :action => :index)
    end
  end

end
