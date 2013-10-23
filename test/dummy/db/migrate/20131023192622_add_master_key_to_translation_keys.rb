class AddMasterKeyToTranslationKeys < ActiveRecord::Migration
  def change
    add_column :tr8n_translation_keys, :master_key, :string
    add_index :tr8n_translation_keys, [:master_key], :name => :tr8n_tk_mk
  end
end
