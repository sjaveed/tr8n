class AdjustForumTableColumns < ActiveRecord::Migration
  def up
    rename_column :tr8n_forum_messages, :language_forum_topic_id, :topic_id
  end

  def down
    rename_column :tr8n_forum_messages, :topic_id, :language_forum_topic_id
  end
end
