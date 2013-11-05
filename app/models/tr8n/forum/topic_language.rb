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
#
#-- Tr8n::Forum::TopicLanguage Schema Information
#
# Table name: tr8n_forum_topic_languages
#
#  id             integer                        not null, primary key
#  language_id    integer                        
#  topic_id       integer                        
#  created_at     timestamp without time zone    not null
#  updated_at     timestamp without time zone    not null
#
# Indexes
#
#  tr8n_toplang    (language_id) 
#
#++

class Tr8n::Forum::TopicLanguage < ActiveRecord::Base
  self.table_name = :tr8n_forum_topic_languages
  attr_accessible :topic_id, :language_id
  attr_accessible :language, :topic

  belongs_to :language, :class_name => "Tr8n::Language"
  belongs_to :topic, :class_name => "Tr8n::Forum::Topic", :foreign_key => :topic_id

  def self.find_or_create(topic, language)
    where("language_id = ? and topic_id = ?", language.id, topic.id).first || create(:topic => topic, :language => language)
  end

end
