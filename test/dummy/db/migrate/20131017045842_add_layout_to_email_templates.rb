class AddLayoutToEmailTemplates < ActiveRecord::Migration
  def change
    add_column :tr8n_email_templates, :layout,  :string
    add_column :tr8n_email_templates, :version, :integer
    add_column :tr8n_email_templates, :state,   :string
  end
end
