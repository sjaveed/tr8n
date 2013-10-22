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

class Tr8n::RequestsController < Tr8n::BaseController

  skip_before_filter :validate_current_translator
  skip_before_filter :validate_guest_user
  skip_before_filter :validate_current_user

  before_filter :validate_request

  # general mechanism for request redirection
  def index
    @request.mark_as_viewed! if @request.delivered?
    redirect_to(@request.destination_url)
  end

  def invite_translator
    if request.post?
      if tr8n_current_user
        trfn("You have accepted request to translate application")
        @request.accept(tr8n_current_user)
        return redirect_to(:controller => "/tr8n/app/phrases", :action => :index, :app_id => @request.application.id)
      end

      return redirect_to("#{Tr8n::Config.signup_url}?id=#{@request.key}")
    end
  end

private

  def validate_request
    @request = Tr8n::Requests::Base.find_by_key(params[:id])

    unless @request
      trfe("Invalid request url")
      return redirect_to(Tr8n::Config.default_url)
    end

    if @request.expired?
      trfe("This request has expired")
      return redirect_to(Tr8n::Config.default_url)
    end

    login!(@request.to) if @request.to
  end

end