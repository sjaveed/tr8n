class AddContextToTranslations < ActiveRecord::Migration
  def change
    add_column :tr8n_translations, :context, :text
  end
end
