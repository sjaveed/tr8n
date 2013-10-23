class AddTypeAndUrlToApplications < ActiveRecord::Migration
  def change
    add_column :tr8n_applications, :type, :string
    add_column :tr8n_applications, :url, :string
  end
end
