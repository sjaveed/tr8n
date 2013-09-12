class AddPositionToApplicationLanguages < ActiveRecord::Migration
  def change
    add_column :tr8n_application_languages, :position, :integer
  end
end
