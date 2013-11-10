class AddDefinitionToApplications < ActiveRecord::Migration
  def change
    add_column :tr8n_applications, :definition, :text
  end
end
