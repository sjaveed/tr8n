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
#-- Tr8n::Notifications::TranslatorFollowing Schema Information
#
# Table name: tr8n_notifications
#
#  id               integer                        not null, primary key
#  type             character varying(255)         
#  translator_id    integer                        
#  actor_id         integer                        
#  target_id        integer                        
#  action           character varying(255)         
#  object_type      character varying(255)         
#  object_id        integer                        
#  viewed_at        timestamp without time zone    
#  created_at       timestamp without time zone    not null
#  updated_at       timestamp without time zone    not null
#
# Indexes
#
#  tr8n_notifs_obj       (object_type, object_id) 
#  tr8n_notifs_trn_id    (translator_id) 
#
#++

class Tr8n::Notifications::TranslatorFollowing < Tr8n::Notification

  def self.distribute(tf)
    return unless tf.object
    if tf.object.is_a?(Tr8n::Translator)
      create(:translator => tf.object, :object => tf, :actor => tf.translator, :target => tf.object, :action => "got_followed")
      create(:translator => tf.translator, :object => tf, :actor => tf.translator, :target => tf.object, :action => "followed_translator")
    end
  end

  def title
    if action == "got_followed"
      return tr("[link: {user}] is now following your translation activity.", nil, 
          :user => actor, :link => {:href => actor.url}
      )
    end

    tr("You are now following [link: {user}]'s translation activity.", nil, 
      :user => target, :link => {:href => target.url}
    )
  end
end
