class AddEmailAssets < ActiveRecord::Migration
  def up
    create_table :tr8n_email_assets do |t|
      t.integer :application_id
      t.string  :keyword
      t.string  :path
      t.text    :thumbnails
      t.timestamps
    end

    add_index :tr8n_email_assets, [:application_id, :keyword], :name => :tr8n_ea_a_k
  end

  def down
    drop_table :tr8n_email_assets
  end
end
