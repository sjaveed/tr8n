class AddPositionToComponentSources < ActiveRecord::Migration
  def change
    add_column :tr8n_component_sources, :position, :integer
  end
end
