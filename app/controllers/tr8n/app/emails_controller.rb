#--
# Copyright (c) 2010-2012 Michael Berkovich, tr8nhub.com
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

class Tr8n::App::EmailsController < Tr8n::App::BaseController

  def index
    @emails = selected_application.emails
  end

  def partials
    @partials = selected_application.email_partials
  end

  def layouts
    @layouts = selected_application.email_layouts
  end

  def template
    @et = Tr8n::EmailTemplate.find_by_id(params[:id])
    if request.post?
      if params[:email_template][:tokens].blank?
        params[:email_template][:tokens] = "{}"
      end
      params[:email_template][:tokens] = JSON.parse(params[:email_template][:tokens])
      @et.update_attributes(params[:email_template])
    end
  end

  def save_template
    #Tr8n::Logger.debug(params.inspect)

    et = Tr8n::EmailTemplate.find_by_id(params[:id])
    et.keyword = params[:keyword]
    et.name = params[:name] if params[:name]
    et.description = params[:description] if params[:description]
    et.subject = params[:subject] if params[:subject]
    et.tokens = JSON.parse(params[:tokens]) if params[:tokens]
    et.html_body = params[:html_body] if params[:html_body]
    et.text_body = params[:text_body] if params[:text_body]

    if params[:parent_id]
      et.parent_id = params[:parent_id] == "-1" ? nil : params[:parent_id]
    end

    et.save
    render :json => {"status" => "Ok"}
  end

  def preview
    @et = Tr8n::EmailTemplate.find_by_id(params[:id])
    @title = "Preview #{@et.title} (#{params[:mode]} mode)"
    @subject = @et.render_subject
    @body = @et.render_body(params[:mode])

    if params[:mode] == "text"
      @body = @body.gsub("\n", "<br>").html_safe
    end

    render :layout => "/tr8n/emails/translate"
  end

  def delete_template
    et = Tr8n::EmailTemplate.find_by_id(params[:id]) if params[:id]
    et.destroy if et
    return redirect_to :action => :layouts if et.is_a?(Tr8n::EmailLayout)
    return redirect_to :action => :partials if et.is_a?(Tr8n::EmailPartial)
    redirect_to :action => :index
  end

end