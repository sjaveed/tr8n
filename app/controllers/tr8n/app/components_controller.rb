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

class Tr8n::App::ComponentsController < Tr8n::App::BaseController

  before_filter :validate_application_management

  def index
    @column_width = 470    # 3 columns
    @mode = (params[:mode] || :grid).to_sym
    @components = selected_application.components
    # @column_width = 1165   # 1 column
    # @column_width = 578     # 2 columns
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

  def component_modal
    @component = Tr8n::Component.find(params[:id])
    if request.post?
      @component.update_attributes(params[:component])
      return redirect_back
    end
    render :layout => false
  end

  def sources
    @sources = selected_application.sources.order("created_at desc")
    unless params[:search].blank?
      @sources = @sources.where("lower(source) like ? or lower(name) like ? or lower(description) like ?", "%#{params[:search].downcase}%", "%#{params[:search].downcase}%", "%#{params[:search].downcase}%")
    end
    @sources = @sources.page(page).per(per_page)
  end

  def source_modal
    @source = Tr8n::TranslationSource.find_by_id(params[:id]) if params[:id]
    @source ||= Tr8n::TranslationSource.new
    if request.post?
      @source.update_attributes(params[:source].merge(:application => selected_application))
      return redirect_back
    end
    render :layout => false
  end

  def add_sources_modal
    @component = Tr8n::Component.find(params[:id])
    if request.post?

      unless params[:sources].blank?
        params[:sources].split(',').each do |src_id|
          src = Tr8n::TranslationSource.find_by_id(src_id)
          @component.add_source(src) if src
        end
      end

      return redirect_back
    end
    render :layout => false
  end


  def delete_sources
    sources = params[:sources].split(",")
    sources.each do |src_id|
      src = Tr8n::TranslationSource.find_by_id(src_id)
      next unless src
      src.destroy
    end

    trfn("Source has been deleted")
    redirect_back
  end

  def add_to_component_modal
    if request.post?
      srcs = []
      params[:sources].split(",").each do |src_id|
        src = Tr8n::TranslationSource.find_by_id(src_id)
        next unless src
        srcs << src
      end

      unless params[:components].blank?
        params[:components].split(",").each do |cmp_id|
          cmp = Tr8n::Component.find_by_id(cmp_id)
          next unless cmp
          srcs.each do |src|
            cmp.add_source(src)
          end
        end
      end

      unless params[:component_key].blank?
        cmp = Tr8n::Component.find_or_create(params[:component_key], selected_application)
        cmp.name = params[:component_name]
        cmp.description = params[:component_description]
        cmp.save
        srcs.each do |src|
          cmp.add_source(src)
        end
      end

      trfn("Sources have been added to specified components")
      return redirect_back
    end

    render :layout=>false
  end

  def view
    @component = Tr8n::Component.find_by_id(params[:id])
  end

  def languages
    @component = Tr8n::Component.find_by_id(params[:id])
  end

  def add_all_languages
    component = Tr8n::Component.find(params[:id])
    component.application.languages.each do |lang|
      component.add_language(lang)
    end
    redirect_back
  end

  def add_languages_modal
    @component = Tr8n::Component.find(params[:id])
    if request.post?
      unless params[:locales].blank?
        params[:locales].split(',').each do |locale|
          lang = Tr8n::Language.by_locale(locale)
          @component.add_language(lang) if lang
        end
      end
      return redirect_back
    end
    render :layout => false
  end

  def remove_language
    cl = Tr8n::ComponentLanguage.find_by_id(params[:id])
    if cl
      cl.destroy
      trfn("Language has been removed")
    end

    redirect_back
  end

  def translators
    @component = Tr8n::Component.find_by_id(params[:id])
  end

  def add_all_translators
    component = Tr8n::Component.find(params[:id])
    component.application.translators.each do |t|
      component.add_translator(t)
    end
    redirect_back
  end

  def add_translators_modal
    @component = Tr8n::Component.find(params[:id])
    if request.post?
      unless params[:translators].blank?
        params[:translators].split(',').each do |tid|
          t = Tr8n::Translator.find_by_id(tid)
          @component.add_translator(t) if t
        end
      end
      return redirect_back
    end
    render :layout => false
  end

  def remove_translator
    cl = Tr8n::ComponentTranslator.find_by_id(params[:id])
    if cl
      cl.destroy
      trfn("Translator has been removed")
    end

    redirect_back
  end

end
