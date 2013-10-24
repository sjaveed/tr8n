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
#-- Tr8n::Emails::Log Schema Information
#
# Table name: tr8n_email_logs
#
#  id                   integer                        not null, primary key
#  email_template_id    integer                        
#  language_id          integer                        
#  from_id              integer                        
#  to_id                integer                        
#  email                character varying(255)         
#  tokens               text                           
#  sent_at              timestamp without time zone    
#  viewed_at            timestamp without time zone    
#  created_at           timestamp without time zone    not null
#  updated_at           timestamp without time zone    not null
#
# Indexes
#
#  index_tr8n_email_logs_on_email                (email) 
#  index_tr8n_email_logs_on_email_template_id    (email_template_id) 
#  index_tr8n_email_logs_on_from_id              (from_id) 
#  index_tr8n_email_logs_on_to_id                (to_id) 
#
#++

class Tr8n::Emails::Log < ActiveRecord::Base
  self.table_name = :tr8n_email_logs

  attr_accessible :application, :language, :translator, :email, :sent_at, :viewed_at, :from, :to, :email_template, :tokens

  belongs_to :email_template, :class_name => 'Tr8n::Emails::Template', :foreign_key => :email_template_id
  belongs_to :language, :class_name => 'Tr8n::Language'

  belongs_to :from, :class_name => Tr8n::Config.user_class_name, :foreign_key => :from_id
  belongs_to :to, :class_name => Tr8n::Config.user_class_name, :foreign_key => :to_id

  serialize :tokens


end
