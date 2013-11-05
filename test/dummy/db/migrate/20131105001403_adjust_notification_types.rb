class AdjustNotificationTypes < ActiveRecord::Migration
  def up
    Tr8n::Notification.connection.execute("update tr8n_notifications set type = 'Tr8n::Notifications::Message' where type = 'Tr8n::Notifications::LanguageForumMessage'")
  end

  def down
  end
end
