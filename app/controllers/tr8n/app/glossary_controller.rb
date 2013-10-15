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

class Tr8n::App::GlossaryController < Tr8n::App::BaseController

  before_filter :validate_current_translator
  
  def index
    @terms = Tr8n::Glossary.where("application_id is null or application_id = ?", selected_application.id).order("keyword asc")
    unless params[:search].blank?
      @terms = @terms.where("(keyword like ? or description like ?)", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    @terms = @terms.page(page).per(per_page)
  end

  def term_modal
    @term = Tr8n::Glossary.find_by_id(params[:id]) if params[:id]
    @term ||= Tr8n::Glossary.new
    if request.post?
      @term.keyword = params[:term][:keyword]
      @term.description = params[:term][:description]
      @term.application = selected_application
      @term.save
      return redirect_back
    end
    render :layout => false
  end

  def delete_term
    @term = Tr8n::Glossary.find_by_id(params[:id]) if params[:id]
    @term.destroy if @term
    redirect_back
  end
end