class CreateForumTopicLanguages < ActiveRecord::Migration
  def up
    create_table :tr8n_forum_topic_languages do |t|
      t.integer :language_id
      t.integer :topic_id
      t.timestamps
    end

    add_index :tr8n_forum_topic_languages, [:language_id], :name => :tr8n_toplang
  end

  def down
    drop_table :tr8n_forum_topic_languages
  end
end
