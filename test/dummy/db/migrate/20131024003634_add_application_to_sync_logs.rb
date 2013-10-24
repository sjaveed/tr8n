class AddApplicationToSyncLogs < ActiveRecord::Migration
  def change
    add_column  :tr8n_sync_logs, :application_id, :integer
    add_column  :tr8n_sync_logs, :data, :text
    add_column  :tr8n_sync_logs, :type, :string
    add_index   :tr8n_sync_logs, [:application_id], :name => :tr8n_sl_a_id
  end
end
