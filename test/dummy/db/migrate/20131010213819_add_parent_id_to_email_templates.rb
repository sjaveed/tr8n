class AddParentIdToEmailTemplates < ActiveRecord::Migration
  def change
    add_column :tr8n_email_templates, :parent_id, :integer
  end
end
