class AddPositionToComponents < ActiveRecord::Migration
  def change
    add_column :tr8n_components, :position, :integer
  end
end
