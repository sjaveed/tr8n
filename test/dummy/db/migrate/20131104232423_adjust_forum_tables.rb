class AdjustForumTables < ActiveRecord::Migration
  def up
    rename_table :tr8n_language_forum_topics, :tr8n_forum_topics
    rename_table :tr8n_language_forum_messages, :tr8n_forum_messages

    Tr8n::Notification.connection.execute("update tr8n_notifications set object_type = 'Tr8n::Forum::Message' where  object_type = 'Tr8n::LanguageForumMessage'")
    Tr8n::Notification.connection.execute("update tr8n_translator_reports set object_type = 'Tr8n::Forum::Message' where  object_type = 'Tr8n::LanguageForumMessage'")
  end

  def down
  end
end
