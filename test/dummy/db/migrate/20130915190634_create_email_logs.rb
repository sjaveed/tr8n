class CreateEmailLogs < ActiveRecord::Migration
  def up
    create_table :tr8n_email_logs do |t|
      t.integer   :email_template_id
      t.integer   :language_id
      t.integer   :from_user_id
      t.integer   :to_user_id
      t.string    :email
      t.text      :tokens
      t.timestamp :sent_at
      t.timestamp :viewed_at
      t.timestamps
    end

    add_index :tr8n_email_logs, [:email_template_id]
    add_index :tr8n_email_logs, [:from_user_id]
    add_index :tr8n_email_logs, [:to_user_id]
    add_index :tr8n_email_logs, [:email]
  end

  def down
    drop_table :tr8n_email_logs
  end
end
