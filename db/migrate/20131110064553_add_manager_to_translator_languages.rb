class AddManagerToTranslatorLanguages < ActiveRecord::Migration
  def change
    add_column :tr8n_translator_languages, :manager, :boolean
  end
end
