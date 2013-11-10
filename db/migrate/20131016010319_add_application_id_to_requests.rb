class AddApplicationIdToRequests < ActiveRecord::Migration
  def change
    add_column :tr8n_requests, :application_id, :integer
    add_index :tr8n_requests, [:type, :application_id, :email], :name => :tr8n_req_t_a_e
  end
end
