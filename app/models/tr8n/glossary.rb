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
#-- Tr8n::Glossary Schema Information
#
# Table name: tr8n_glossary
#
#  id                integer                        not null, primary key
#  keyword           character varying(255)         
#  description       text                           
#  created_at        timestamp without time zone    not null
#  updated_at        timestamp without time zone    not null
#  application_id    integer                        
#  language_id       integer                        
#
# Indexes
#
#  index_tr8n_glossary_on_keyword    (keyword) 
#  tr8n_g_a                          (application_id) 
#
#++

class Tr8n::Glossary < ActiveRecord::Base
  self.table_name = :tr8n_glossary
  
  attr_accessible :keyword, :description

  belongs_to :application, :class_name => 'Tr8n::Application'
  belongs_to :language, :class_name => 'Tr8n::Language'

  
end
