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

class Tr8n::App::PhrasesController < Tr8n::App::BaseController

  before_filter :init_breadcrumb

  def index
    @translation_keys = Tr8n::TranslationKey.for_params(params.merge(:application => selected_application, :component => @component, :source => @source))

    ## get a list of all restricted keys
    #restricted_keys = Tr8n::TranslationKey.all_restricted_ids
    #
    ## exclude all restricted keys
    #if restricted_keys.any?
    #  @translation_keys =  @translation_keys.where("id not in (?)", restricted_keys)
    #end

    @translation_keys = @translation_keys.order("created_at desc").page(page).per(per_page)

    if @translation_keys.size == 0
      @translated = 0
      @locked = 0
    else
      @translated = Tr8n::RequestContext.current_language.total_metric.translation_completeness
      @locked = Tr8n::RequestContext.current_language.completeness
    end
  end
  
  def view
    unless translation_key
      trfe("This phrase could not be found")
      return redirect_back
    end
    
    @show_add_dialog = (params[:mode] == "add" or translation_key.translations_for(tr8n_current_language).empty?)

    # for new translation
    @translation = Tr8n::Translation.new(:translation_key => translation_key, :language => tr8n_current_language, :translator => tr8n_current_translator)
    @rules = {}
    
    @translations = Tr8n::Translation.for_params(params)
    @translations = @translations.where("tr8n_translations.language_id = ? and tr8n_translations.translation_key_id = ?", tr8n_current_language.id,  translation_key.id)
    @translations = @translations.order("rank desc, created_at desc")
    @comments = Tr8n::TranslationKeyComment.where("language_id = ? and translation_key_id = ?", tr8n_current_language.id, translation_key.id).order("created_at desc").page(page).per(per_page)
    
    @grouping = {}
    if params[:grouped_by] != "nothing"
      @translations.each do |tr|
        case params[:grouped_by]
          when "translator" then
            if tr.translator.user
              key = trl("Translations Created by {user}", "", :user => [tr.translator.user, tr.translator.name])
            else
              key = trl("Translations Created by an Unknown User")
            end
            (@grouping[key] ||= []) << tr
          when "context" then
            if tr.context.blank?
              key = trl("Translations Without Context Rules")
            else
              key = tr.context_description
            end
            (@grouping[key] ||= []) << tr
          when "rank" then
            key = trl("Translations With Rank \"{rank}\"", "", :rank => tr.rank)
            (@grouping[key] ||= []) << tr
          when "date" then
            key = trl("Translations Created On {date}", "", :date => tr.created_at.trl(:verbose))
            (@grouping[key] ||= []) << tr
        end
      end
    end
    
  end

  def lock
    translation_key.lock!
    redirect_back
  end

  def unlock
    translation_key.unlock!
    redirect_back
  end

  def dictionary
    @definitions = Tr8n::Dictionary.load_definitions_for(translation_key.words)
    render :partial => "dictionary", :layout => false
  end
  
  def submit_comment
    Tr8n::TranslationKeyComment.create(:language => tr8n_current_language,
                                       :translator => tr8n_current_translator,
                                       :translation_key => translation_key,
                                       :message => params[:message])

    trfn("Comment has been added.")
    redirect_back
  end

  def delete_comment
    comment = Tr8n::TranslationKeyComment.find_by_id(params[:comment_id]) unless params[:comment_id].blank?
    comment.destroy if comment
    trfn("Comment has been removed.")
    redirect_back
  end

  def lb_sources
    translation_key
    render :layout => 'tr8n/tools/lightbox'
  end
    
  def recalculate_metric
    metric = Tr8n::TranslationSourceMetric.find_by_id(params[:id])
    unless metric
      trfe("Invalid metric id")
      return redirect_to_source
    end

    metric.update_metrics!
    redirect_to_source
  end

private

  def translation_key
    @translation_key ||= Tr8n::TranslationKey.find(params[:id] || params[:translation_key_id])
  end
  helper_method :translation_key

  def sources_from_params
    # unless params[:section_key].blank?
    #   return sitemap_sources_for(@section_key) 
    # end

    unless params[:sources].blank?
      source_ids = params[:sources].split(',')
      return [] if source_ids.empty?
      return Tr8n::TranslationSource.where("id in (?)", source_ids).all
    end    

    unless params[:source_id].blank?
      source = Tr8n::TranslationSource.find_by_id(params[:source_id])
      return [] unless source
      return [source]
    end

    unless params[:component_id].blank?
      @component = Tr8n::Component.find_by_id(params[:component_id])
      return [] unless @component
      return @component.sources
    end

    []
  end

  def translation_keys_for_sources(sources, keys)
    @selected_sources = []
    @translated = 0
    @locked = 0

    source_ids = []
    sources.each do |source|
      next unless source.translator_authorized?
      source_ids << source.id
      @selected_sources << source
      @locked += (source.total_metric.completeness || 0)
      @translated += (source.total_metric.translation_completeness || 0)
    end

    # avg of the total
    if source_ids.empty?
      @translated = 0
      @locked = 0
      return keys.where("tr8n_translation_keys.id = -1") 
    end

    @locked = @locked/source_ids.size
    @translated = @translated/source_ids.size

    keys = keys.joins(:translation_sources).where("tr8n_translation_sources.id in (?)", source_ids.uniq).uniq
    # where("(tr8n_translation_keys.id in (select distinct(tr8n_translation_key_sources.translation_key_id) from tr8n_translation_key_sources where tr8n_translation_key_sources.translation_source_id in (?)))", source_ids.uniq)
    keys.order("tr8n_translation_keys.created_at desc").page(page).per(per_page)
  end

  def sitemap_sources_for(key)
    section = Tr8n::SiteMap.section_for_key(key)
    sources = []
    section = collect_sitemap_section_sources(section, sources)
    sources.flatten.uniq
  end
  
  def collect_sitemap_section_sources(section, sources)
    sources << section.sources if section.sources
    section.children.each do |section|
      collect_sitemap_section_sources(section, sources)
    end
  end  

private

  def init_breadcrumb
    if params[:component_id]
      @component = Tr8n::Component.find_by_id(params[:component_id])
    end
    if params[:source_id]
      @source = Tr8n::TranslationSource.find_by_id(params[:source_id])
    end
  end

end