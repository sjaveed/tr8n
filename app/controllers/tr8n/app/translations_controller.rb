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

class Tr8n::App::TranslationsController < Tr8n::App::BaseController

  # for ssl access to the dashboard - using ssl_requirement plugin
  ssl_allowed :submit  if respond_to?(:ssl_allowed)
  
  # list of translations    
  def index
    #@translations = Tr8n::Translation.for_params(params.merge(:application => @selected_application, :only_phrases => true))
    #@translations = @translations.order("created_at desc, rank desc").page(page).per(per_page)
    # restricted_keys = Tr8n::TranslationKey.all_restricted_ids

    # # exclude all restricted always
    # if restricted_keys.any?
    #   @translations = @translations.where("translation_key_id not in (?)", restricted_keys)
    # end

    # @translations = Tr8n::Translation.for_params(params).order("created_at desc, rank desc").page(page).per(per_page)

    @translations = Tr8n::Translation.where("tr8n_translations.language_id = ?", Tr8n::RequestContext.current_language.id)
    @source_ids = selected_application.sources.collect{|s| s.id}

    if @source_ids.size > 0
      #@ids = Tr8n::TranslationKeySource.connection.execute("select translation_key_id from tr8n_translation_key_sources where translation_source_id in (#{@source_ids.join(',')})").collect{|r| r["translation_key_id"]}
      @translations = @translations.where("tr8n_translations.translation_key_id in (select tr8n_translation_key_sources.translation_key_id from tr8n_translation_key_sources where translation_source_id in (#{@source_ids.join(',')}))", @ids)
    else
      @translations = @translations.where("1=2")
    end

    if params[:with_status] == "accepted"
      @translations = @translations.where("tr8n_translations.rank >= ?", selected_application.threshold)
    elsif params[:with_status] == "pending"
      @translations = @translations.where("tr8n_translations.rank >= 0 and tr8n_translations.rank < ?", selected_application.threshold)
    elsif params[:with_status] == "rejected"
      @translations = @translations.where("tr8n_translations.rank < 0")
    end

    params[:submitted_by] = nil if params[:submitted_by] == "anyone"
    unless params[:submitted_by].blank?
      if params[:submitted_by] == "me"
        @translations = @translations.where("tr8n_translations.translator_id = ?", Tr8n::RequestContext.current_user_is_translator? ? Tr8n::RequestContext.current_translator.id : 0)
      else
        @translations = @translations.where("tr8n_translations.translator_id = ?", params[:submitted_by].id)
      end
    end

    if params[:submitted_on] == "today"
      date = Date.today
      @translations = @translations.where("tr8n_translations.created_at >= ? and tr8n_translations.created_at < ?", date, date + 1.day)
    elsif params[:submitted_on] == "yesterday"
      date = Date.today - 1.days
      @translations = @translations.where("tr8n_translations.created_at >= ? and tr8n_translations.created_at < ?", date, date + 1.day)
    elsif params[:submitted_on] == "last_week"
      date = Date.today - 7.days
      @translations = @translations.where("tr8n_translations.created_at >= ? and tr8n_translations.created_at < ?", date, Date.today)
    end

    unless params[:search].blank?
      @translations = @translations.where("tr8n_translations.label like ?", "%#{params[:search]}%")
    end

    @translations = @translations.order("tr8n_translations.id desc").page(page).per(per_page).includes(:translation_key)

    @followed_translators = tr8n_current_translator.followed_objects("Tr8n::Translator")
    unless [nil, "", "anyone", "me"].include?(params[:submitted_by])
      dashboard = Tr8n::Translator.find_by_id(params[:submitted_by])
      if dashboard
        if dashboard == tr8n_current_translator
          params[:submitted_by] = :me
        elsif not @followed_translators.include?(dashboard)
          @followed_translators << dashboard
        end
      end
    end
  end

  # main translation method used by the dashboard and translation screens
  def submit
    if params[:destination_url]
      destination_url = params[:destination_url]
    elsif params[:origin]
      destination_url = {:controller => '/tr8n/tools/translator', :action => 'done', :id => params[:id], :origin => params[:origin]}
    else
      destination_url = {:controller => '/tr8n/app/phrases', :action => :view, :id => translation_key.id, :component_id => params[:component_id], :source_id => params[:source_id]}
    end

    if params[:lock] == "true"
      if tr8n_current_translator.manager?
        if translation_key.locked?
          translation_key.unlock!
        else
          translation_key.lock!
        end
      else
        trfe("You are not authorized to lock translation keys")
      end
      return redirect_to(destination_url)
    end

    if params[:translation_id].blank?
      translation = Tr8n::Translation.new(:translation_key => translation_key, :language => tr8n_current_language, :translator => tr8n_current_translator)
    else  
      translation = Tr8n::Translation.find_by_id(params[:translation_id].to_i)
      unless translation
        trfe("Invalid translation id")
        return redirect_to(destination_url)
      end
    end

    translation.label = sanitize_label(params[:translation][:label])
    translation.context = parse_rules

    unless translation.can_be_edited_by?(tr8n_current_translator)
      tr8n_current_translator.tried_to_perform_unauthorized_action!("tried to update translation which is locked or belongs to another dashboard")
      trfe("You are not authorized to edit this translation")
      return redirect_to(destination_url)
    end  

    if translation.blank?
      tr8n_current_translator.tried_to_perform_unauthorized_action!("tried to submit an empty translation")
      trfe("Your translation was empty and was not accepted")
      return redirect_to(destination_url)
    end
    
    unless translation.uniq?
      tr8n_current_translator.tried_to_perform_unauthorized_action!("tried to submit an identical translation")
      trfe("There already exists such translation for this phrase. Please vote on it instead or suggest an elternative translation.")
      return redirect_to(destination_url)
    end
    
    unless translation.clean?
      tr8n_current_translator.used_abusive_language!
      trfe("Your translation contains prohibited words and will not be accepted")
      return redirect_to(destination_url)
    end

    translation.save_with_log!(tr8n_current_translator)
    translation.reset_votes!(tr8n_current_translator)

    redirect_to(destination_url)
  end
  
  # generates phrase context rules permutations
  # can be called from the dashboard or from a page
  def permutate
    new_translations = translation_key.generate_translations_for_rules_combinations(tr8n_current_language, tr8n_current_translator, params[:token_contexts])

    if params[:translator]
      return redirect_to(:controller => '/tr8n/tools/translator',
                         :action => :permutations,
                         :id => translation_key.id,
                         :origin => params[:origin],
                         :translation_ids => new_translations.collect{|trn| trn.id}.join(','))

    end

    if params[:token_contexts].blank?
      trfe('No context rules were specified.')
    elsif new_translations.nil? or new_translations.empty?
      trfn('The context rules already exist. Please provide a translation for each rule.')
    else
      trfn('All possible combinations of the context rules for this phrase have been generated. Please provide a translation for each rule.')
    end

    redirect_to(:controller => "/tr8n/app/phrases", :action => :view, :id => translation_key.id, :grouped_by => :context)
  end
  
  # ajax based method - collects votes for a translation
  def vote
    translation.vote!(tr8n_current_translator, params[:vote])

    # this is called from translations page
    if params[:short_version] == "true"
      return render(:text => translation.rank_label) 
    end
    
    # this is called from the inline dashboard with reordering the translations based on ranks
    render(:partial => '/tr8n/common/translation_votes',
           :locals => {:translation_key => translation.translation_key,
           :translations => translation.translation_key.inline_translations_for(tr8n_current_language)})
  end


  # ajax based method for updating individual translations
  def update
    #coming from translator window
    if params[:translations]
      params[:translations].each do |tid, label|
        trn = Tr8n::Translation.find_by_id(tid)
        next unless trn
        trn.label = sanitize_label(label)
        next if trn.blank?
        next unless trn.uniq?
        next unless trn.clean?
        trn.save_with_log!(tr8n_current_translator)
        trn.reset_votes!(tr8n_current_translator)
      end

      return redirect_to(:controller => '/tr8n/tools/translator', :action => 'done', :id => translation_key.id, :origin => params[:origin])
    end

    @translation = Tr8n::Translation.find(params[:translation_id])
    mode = params[:mode] || :view
    if request.post?
      mode = :view
      unless params[:label].strip.blank?
        @translation.label = sanitize_label(params[:label])
        
        unless @translation.can_be_edited_by?(tr8n_current_translator)
          tr8n_current_translator.tried_to_perform_unauthorized_action!("tried to update translation that is not his")
          @translation.label = "You are not authorized to edit this translation as you were not it's creator"
          mode = :edit
        else 
          if @translation.blank?
            tr8n_current_translator.tried_to_perform_unauthorized_action!("tried to submit an empty translation")
            @translation.label = "Your translation was empty and was not accepted"
            mode = :edit
          elsif not @translation.uniq?
            tr8n_current_translator.tried_to_perform_unauthorized_action!("tried to submit an identical translation")
            @translation.label = "There already exists such translation for this phrase. Please vote on it instead or suggest an elternative translation."
            mode = :edit
          elsif not @translation.clean?
            tr8n_current_translator.used_abusive_language!
            @translation.label = "Your translation contains prohibited words and will not be accepted. Click on cancel and try again."
            mode = :edit
          else
            @translation.save_with_log!(tr8n_current_translator)
            @translation.reset_votes!(tr8n_current_translator)
          end
        end

      end
    end
    render(:partial => "translation", :locals => {:language => tr8n_current_language, :translation => @translation, :mode => mode.to_sym})
  end  
  
  # deletes an individual translation
  def delete
    translator = translation.translator

    unless translation.can_be_deleted_by?(tr8n_current_translator)
      tr8n_current_translator.tried_to_perform_unauthorized_action!("tried to delete translation that is not his")
      trfe("You are not authorized to delete this translation as you were not it's creator")
    else
      translation.destroy_with_log!(tr8n_current_translator)
      translator.update_rank!
      trfn("Your translation has been removed.")
    end
    
    redirect_back
  end
    
private

  def translation_key
    @translation_key ||= Tr8n::TranslationKey.find_by_id(params[:id] || params[:translation_key_id])
  end
  helper_method :translation_key

  def translation
    @translation ||= Tr8n::Translation.find_by_id(params[:translation_id])
  end
  helper_method :translation

  # context[minutes][number][keyword]
  # context[minutes][number][selected]
  # {"minutes"=>{"number"=>{"keyword"=>"many", "selected"=>"on"}}, "viewing_user"=>{"gender"=>{"keyword"=>"male", "selected"=>"on"}}}
  def parse_rules
    return nil unless params[:may_have_context] == "true" and params[:context]

    context = {}
    params[:context].each do |token, ctx|
      ctx.each do |key, data|
        next unless data[:selected] == "on"
        next if data[:keyword].blank?
        context[token] = {key => data[:keyword]}
      end
    end

    return nil if context.blank?
    context
  end

end