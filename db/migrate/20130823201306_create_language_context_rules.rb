class CreateLanguageContextRules < ActiveRecord::Migration
  def change
    create_table :tr8n_language_context_rules do |t|
      t.integer :language_context_id
      t.integer :translator_id
      t.string  :keyword
      t.string  :description
      t.string  :examples
      t.text    :definition
      t.timestamps
    end

    add_index :tr8n_language_context_rules, [:language_context_id, :keyword], :name => :tr8n_lctxr_lci
  end
end
