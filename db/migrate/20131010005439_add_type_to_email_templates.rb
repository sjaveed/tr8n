class AddTypeToEmailTemplates < ActiveRecord::Migration
  def up
    rename_column :tr8n_email_templates, :body, :html_body
    add_column :tr8n_email_templates, :text_body, :text
    add_column :tr8n_email_templates, :type, :string
    add_index :tr8n_email_templates, [:type, :application_id, :keyword], :name => :tr8n_et_t_a
  end

  def down
    rename_column :tr8n_email_templates, :html_body, :body
    remove_column :tr8n_email_templates, :text_body
    remove_column :tr8n_email_templates, :type
  end
end
