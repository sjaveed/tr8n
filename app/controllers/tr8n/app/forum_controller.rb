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

class Tr8n::App::ForumController < Tr8n::App::BaseController

  before_filter :validate_current_translator
  
  def index
    @topics = Tr8n::Forum::Topic.where("tr8n_forum_topics.language_id = ? or tr8n_forum_topics.language_id is null or tr8n_forum_topics.id in (select tr8n_forum_topic_languages.topic_id from tr8n_forum_topic_languages where tr8n_forum_topic_languages.language_id = ?)", tr8n_current_language.id, tr8n_current_language.id)
    @topics = @topics.order("created_at desc").page(page).per(per_page)
  end

  def topic
    if request.post?
      if params[:id]
        topic = Tr8n::Forum::Topic.find_by_id(params[:id])
      else
        topic = Tr8n::Forum::Topic.create(:translator => tr8n_current_translator, :topic => params[:topic])
        unless params[:locales].blank?
          params[:locales].split(',').each do |locale|
            lang = Tr8n::Language.by_locale(locale)
            next unless lang
            unless topic.language
              topic.language = lang
              topic.save
            end
            Tr8n::Forum::TopicLanguage.find_or_create(topic, lang)
          end
        end
      end
      
      Tr8n::Forum::Message.create(
          :topic => topic,
          :language => tr8n_current_language,
          :message => params[:message],
          :translator => tr8n_current_translator,
          :mentions => params[:mentioned_translators]
      )
      return redirect_to(:action => :topic, :id => topic.id, :last_page => true)
    end
    
    unless params[:mode] == "create"
      @topic = Tr8n::Forum::Topic.find_by_id(params[:id])
      if params[:last_page]
        params[:page] = (@topic.post_count / per_page.to_i) 
        params[:page] += 1 unless (@topic.post_count % per_page.to_i == 0) 
      end

      @messages = Tr8n::Forum::Message.where(:topic_id => @topic.id).order("created_at asc").page(page).per(per_page)
    end
  end

  def delete_topic
    topic = Tr8n::Forum::Topic.find_by_id(params[:id])
    
    if topic.translator != tr8n_current_translator
      trfe("You cannot delete topics you didn't create.")
      return redirect_to(:action => :index)
    end
    
    topic.destroy if topic
    trfn("The topic {topic} has been removed", 'Tr8n Forum', :topic => "\"#{topic.topic}\"")
    redirect_to(:action => :index)
  end

  def delete_message
    message = Tr8n::Forum::Message.find_by_id(params[:message_id])
    
    unless message
      trfe("This message does not exist")
      return redirect_to(:action => :index)
    end  

    if message.translator != tr8n_current_translator
      trfe("You cannot delete messages you didn't post.")
      redirect_to(:action => :topic, :topic_id => message.forum_topic.id)
    end
    
    message.destroy
    trfn("The message has been removed")
    redirect_to(:action => :topic, :id => message.topic.id)
  end  

end
