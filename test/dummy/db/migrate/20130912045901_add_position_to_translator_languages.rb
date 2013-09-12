class AddPositionToTranslatorLanguages < ActiveRecord::Migration
  def change
    add_column :tr8n_translator_languages, :position, :integer
  end
end
