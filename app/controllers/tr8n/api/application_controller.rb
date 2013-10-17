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

###########################################################################
## API for getting translations from the main server
###########################################################################

class Tr8n::Api::ApplicationController < Tr8n::Api::BaseController
  # for ssl access to the dashboard - using ssl_requirement plugin
  ssl_allowed :sync  if respond_to?(:ssl_allowed)

  before_filter :validate_remote_application, :only => [:translations]

  def index
    ensure_get
    ensure_application
    render_response(application.to_api_hash(:definition => params[:definition]))
  end

  def version
    ensure_get
    ensure_application
    render_response(:version => application.version)
  end

  def languages
    ensure_get
    ensure_application
    render_response(application.languages.collect{|l| l.to_api_hash(:definition => (params[:definition] == "true"))})
  end

  def featured_locales
    ensure_get
    ensure_application
    render_response(application.featured_languages.collect{|lang| lang.locale})
  end

  def sources
    ensure_get
    ensure_application
    render_response(application.sources)
  end

  def components
    ensure_get
    ensure_application
    render_response(application.components)
  end

  def translators
    ensure_get
    ensure_application
    render_response(application.translators)
  end

  def sync
    ensure_push_enabled

    sync_log = Tr8n::SyncLog.create(:started_at => Time.now, 
                                    :keys_received => 0, :translations_received => 0, 
                                    :keys_sent => 0, :translations_sent => 0)

    method = params[:method] || "push"
    
    payload = []
    
    if method == "push"
      payload = push_translations(sync_log)
    
    elsif method == "pull"
      payload = pull_translations(sync_log)
      
    end

    sync_log.finished_at = Time.now
    sync_log.save
    
    render_response(:translation_keys => payload)    
  rescue Tr8n::Exception => ex
    render_error(ex.message)    
  end

  def translations
    languages = tr8n_current_application.languages
    source_ids = tr8n_current_application.sources.collect{|src| src.id}

    @filename = "translations_#{Date.today.to_s(:db)}.json"
    self.response.headers["Content-Type"] ||= 'text/json'
    self.response.headers["Content-Disposition"] = "attachment; filename=#{@filename}"
    self.response.headers['Last-Modified'] = Time.now.ctime.to_s

    lang_ids = languages.collect{|l| l.id}

    locales = {}
    Tr8n::Language.all.each do |l|
      locales[l.id.to_s] = l.locale
    end

    self.response_body = Enumerator.new do |results|
      t = 0
      tk = 0

      sql =  %"
select tr8n_translations.translation_key_id as translation_key_id, tr8n_translation_keys.key as translation_key_hash, tr8n_translation_keys.label as translation_key_label, tr8n_translation_keys.description as translation_key_description,
       tr8n_translations.language_id as translation_language_id, tr8n_translations.label as translation_label, tr8n_translations.context as translation_context
from tr8n_translations
inner join tr8n_translation_keys on tr8n_translations.translation_key_id = tr8n_translation_keys.id
where tr8n_translations.translation_key_id in (select tr8n_translation_key_sources.translation_key_id from tr8n_translation_key_sources where tr8n_translation_key_sources.translation_source_id in (#{source_ids.join(',')}))
order by tr8n_translations.translation_key_id asc
limit 1000000
offset 0;
"
      #pp sql
      tkey = nil
      Tr8n::Translation.connection.execute(sql).each do |rec|
        #pp rec["translation_key_label"]

        if tkey.nil? or tkey["id"] != rec["translation_key_id"]
          unless tkey.nil?
            results << "#{tkey.to_json}\n"
            pp "#{tk} keys and #{t} translations have been sent" if tk % 1000 == 0
          end

          tkey = {
              "key"           => rec["translation_key_hash"],
              "id"            => rec["translation_key_id"],
              "label"         => rec["translation_key_label"],
              "translations"  => {}
          }

          unless rec["translation_key_description"].blank?
            tkey["description"] = rec["translation_key_description"]
          end

          tk += 1
        end

        locale = locales[rec["translation_language_id"].to_s]
        next unless locale
        tkey["translations"][locale] = [
            {"label" => rec["translation_label"]}
        ]
        t += 1

        #GC.start if i % 500==0
      end
      pp "#{tk} keys and #{t} translations have been sent"
    end
  end

private

  def ensure_push_enabled
    raise Tr8n::Exception.new("Push is disabled") unless Tr8n::Config.synchronization_push_enabled?
    raise Tr8n::Exception.new("Unauthorized server push attempt") unless Tr8n::Config.synchronization_push_servers.include?(request.env['REMOTE_HOST'])
  end
  
  def translator
    @translator ||= Tr8n::Config.system_translator
  end
  
  def sync_languages
    @sync_languages ||= Tr8n::Language.enabled_languages
  end
  
  def batch_size
    @batch_size ||= Tr8n::Config.synchronization_batch_size
  end
  
  def push_translations(sync_log, opts = {})
    payload = []

    # already parsed by Rails
    # keys = JSON.parse(params[:translation_keys])
    keys = params[:translation_keys]
    return payload unless keys
  
    sync_log.keys_received += keys.size
  
    keys.each do |tkey_hash|
      # pp tkey_hash
      tkey, remaining_translations = Tr8n::TranslationKey.create_from_sync_hash(tkey_hash, translator)
      next unless tkey

      sync_log.translations_received += tkey_hash[:translations].size if tkey_hash[:translations]
      sync_log.translations_sent += remaining_translations.size

      tkey.mark_as_synced!
    
      payload << tkey.to_sync_hash(:translations => remaining_translations, :languages => sync_languages)
    end
    
    payload
  end
  
  def pull_translations(sync_log, opts = {})
    payload = []
  
    # find all keys that have changed since the last sync
    changed_keys = Tr8n::TranslationKey.where("synced_at is null or updated_at > synced_at").limit(batch_size)
    sync_log.keys_sent += changed_keys.size
    
    changed_keys.each do |tkey|
      tkey_hash = tkey.to_sync_hash(:languages => sync_languages)
      payload << tkey_hash
      sync_log.translations_sent += tkey_hash["translations"].size if tkey_hash["translations"]
      tkey.mark_as_synced!
    end
    
    payload
  end  
  
end