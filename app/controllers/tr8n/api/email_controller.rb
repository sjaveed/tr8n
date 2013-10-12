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

class Tr8n::Api::EmailController < Tr8n::Api::BaseController

  def templates
    ensure_get
    ensure_application

    render_response(application.emails)
  end

  def message
    ensure_post
    ensure_application

    tokens = params[:tokens]
    tokens = JSON.parse(tokens)

    keyword = params[:key]

    email = application.emails.where(:keyword => keyword).first

    unless email
      return render_error("Email not found")
    end

    data = {
      :subject => email.render_subject(tokens, {:skip_decorations => true, :language => language}),
      :html_body => email.render_body(:html, tokens, {:skip_decorations => true, :language => language}),
      :text_body => email.render_body(:text, tokens, {:skip_decorations => true, :language => language})
    }

    render_response(data)
  end

  def deliver
    ensure_post
    ensure_application
  end

end