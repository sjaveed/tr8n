class AddDefaultLocaleToApplication < ActiveRecord::Migration
  def change
    add_column :tr8n_applications, :default_language_id, :integer
  end
end
