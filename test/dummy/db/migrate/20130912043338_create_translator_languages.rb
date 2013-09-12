class CreateTranslatorLanguages < ActiveRecord::Migration
  def up
    create_table :tr8n_translator_languages do |t|
      t.integer :translator_id
      t.integer :language_id
      t.boolean :primary
      t.timestamps
    end

    add_index :tr8n_translator_languages, [:translator_id, :language_id], :name => :tr8n_trn_lang
  end

  def down
    drop_table :tr8n_translator_languages
  end
end
