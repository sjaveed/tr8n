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
#-- Tr8n::Request Schema Information
#
# Table name: tr8n_requests
#
#  id            INTEGER         not null, primary key
#  type          varchar(255)    
#  state         varchar(255)    
#  key           varchar(255)    
#  email         varchar(255)    
#  from_id       integer         
#  to_id         integer         
#  data          text            
#  expires_at    datetime        
#  created_at    datetime        not null
#  updated_at    datetime        not null
#
# Indexes
#
#  index_tr8n_requests_on_to_id                     (to_id) 
#  index_tr8n_requests_on_from_id                   (from_id) 
#  index_tr8n_requests_on_type_and_key_and_state    (type, key, state) 
#
#++

class Tr8n::Request < ActiveRecord::Base
  self.table_name = :tr8n_requests

  attr_accessible :email, :data, :from, :to, :expires_at

  include AASM

  belongs_to :from, :class_name => Tr8n::Config.user_class_name, :foreign_key => "from_id"
  belongs_to :to, :class_name => Tr8n::Config.user_class_name, :foreign_key => "to_id"

  before_create :generate_key

  serialize :data

  aasm :column => :state do
    state :new, :initial => true
    state :delivered
    state :viewed
    state :accepted
    state :rejected
    state :canceled

    event :mark_as_delivered do
      transitions :from => :new,            :to => :delivered
    end

    event :mark_as_viewed do
      transitions :sent => :delivered,      :to => :viewed
    end

    event :mark_as_accepted do
      transitions :from => :new,            :to => :accepted
      transitions :from => :delivered,      :to => :accepted
      transitions :sent => :viewed,         :to => :accepted
    end

    event :mark_as_rejected do
      transitions :from => :delivered,      :to => :rejected
    end

    event :mark_as_canceled do
      transitions :from => :new,            :to => :canceled
      transitions :from => :delivered,      :to => :canceled
      transitions :sent => :viewed,         :to => :canceled
    end
  end

  def self.find_or_create(email)
    find_by_email(email) || create(:email => email)
  end

  def lander_url
    "#{Tr8n::Config.base_url}/tr8n/requests/#{self.class.name.underscore.split("/").last}/#{key}"
  end

  def deliver
    raise "deliver method must be implemented by a subclass"
  end

  def expired?
    return false if expires_at.nil?
    Time.now > expires_at
  end

  def expire_in(interval)
    self.update_attributes(:expires_at => Time.now + interval)
  end

  protected

  def generate_key
    self.key = Tr8n::Utils.guid if key.nil?
  end

end
