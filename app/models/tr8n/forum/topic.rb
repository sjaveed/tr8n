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
#-- Tr8n::Forum::Topic Schema Information
#
# Table name: tr8n_forum_topics
#
#  id               integer                        not null, primary key
#  translator_id    integer                        not null
#  language_id      integer                        
#  topic            text                           not null
#  created_at       timestamp without time zone    not null
#  updated_at       timestamp without time zone    not null
#
# Indexes
#
#  tr8n_lft_l    (language_id) 
#  tr8n_lft_t    (translator_id) 
#
#++

class Tr8n::Forum::Topic < ActiveRecord::Base
  self.table_name = :tr8n_forum_topics
  attr_accessible :translator_id, :language_id, :topic
  attr_accessible :language, :translator

  # primary language
  belongs_to :language, :class_name => "Tr8n::Language"
  belongs_to :translator, :class_name => "Tr8n::Translator"
  
  has_many :messages, :class_name => "Tr8n::Forum::Message", :foreign_key => :topic_id, :dependent => :destroy
  has_many :topic_languages, :class_name => "Tr8n::Forum::TopicLanguage", :foreign_key => :topic_id, :dependent => :destroy
  has_many :languages, :through => :topic_languages

  def post_count
    @post_count ||= Tr8n::Forum::Message.where(:topic_id => self.id).count
  end

  def last_post
    @last_post ||= Tr8n::Forum::Message.where(:topic_id => self.id).order("created_at desc").first
  end

end
