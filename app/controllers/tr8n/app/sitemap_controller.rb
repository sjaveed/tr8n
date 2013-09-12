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

class Tr8n::App::SitemapController < Tr8n::App::BaseController

  def index

  end

  def delete_component
    comp = Tr8n::Component.find_by_id(params[:id])
    if comp
      comp.destroy
      trfn("Component has been deleted")
    end

    redirect_back
  end

  def remove_source
    cs = Tr8n::ComponentSource.find_by_id(params[:id])
    if cs
      cs.destroy
      trfn("Source has been removed")
    end

    redirect_back
  end

  def update_components_order
    params[:components].each_with_index do |id, index|
      Tr8n::Component.update_all({:position => index+1}, {:id => id})
    end

    render :nothing => true
  end

  def update_component_sources_order
    params[:component_sources].each_with_index do |id, index|
      Tr8n::ComponentSource.update_all({:position => index+1}, {:id => id})
    end

    render :nothing => true
  end

end
