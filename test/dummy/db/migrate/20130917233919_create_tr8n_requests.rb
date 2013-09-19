class CreateTr8nRequests < ActiveRecord::Migration
  def up
    create_table :tr8n_requests do |t|
      t.string    :type
      t.string    :state
      t.string    :key
      t.string    :email
      t.integer   :from_id
      t.integer   :to_id
      t.text      :data
      t.timestamp :expires_at

      t.timestamps
    end

    add_index :tr8n_requests, [:type, :key, :state]
    add_index :tr8n_requests, [:from_id]
    add_index :tr8n_requests, [:to_id]
  end

  def down
    drop_table :tr8n_requests
  end
end
