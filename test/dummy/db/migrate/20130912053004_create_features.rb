class CreateFeatures < ActiveRecord::Migration
  def up
    create_table :tr8n_features do |t|
      t.string  :object_type
      t.integer :object_id
      t.string  :keyword
      t.boolean :enabled
      t.timestamps
    end

    add_index :tr8n_features, [:object_type, :object_id], :name => :tr8n_feats
  end

  def down
    drop_table :tr8n_features
  end
end
