class CreateLanguageContexts < ActiveRecord::Migration
  def change
    create_table :tr8n_language_contexts do |t|
      t.integer :language_id
      t.integer :translator_id
      t.string  :keyword
      t.string  :description
      t.text    :definition
      t.timestamps
    end

    add_index :tr8n_language_contexts, [:language_id, :keyword], :name => :tr8n_lctx_lk
  end
end
