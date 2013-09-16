class CreateEmailTemplates < ActiveRecord::Migration
  def up
    create_table :tr8n_email_templates do |t|
      t.integer :application_id
      t.integer :language_id
      t.string  :keyword
      t.string  :name
      t.string  :description
      t.string  :subject
      t.text    :body
      t.text    :tokens
      t.timestamps
    end

    add_index :tr8n_email_templates, [:application_id, :keyword]
  end

  def down
    drop_table :tr8n_email_templates
  end
end
