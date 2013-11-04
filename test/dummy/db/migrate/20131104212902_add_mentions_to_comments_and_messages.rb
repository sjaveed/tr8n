class AddMentionsToCommentsAndMessages < ActiveRecord::Migration
  def change
    add_column :tr8n_translation_key_comments, :mentions, :string
    add_column :tr8n_language_forum_messages, :mentions, :string
  end
end
