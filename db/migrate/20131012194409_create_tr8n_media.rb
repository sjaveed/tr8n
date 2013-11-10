class CreateTr8nMedia < ActiveRecord::Migration
  def up
    create_table :tr8n_media do |t|
      t.string  :type
      t.integer :position
      t.integer :owner_id
      t.string  :owner_type
      t.string  :keyword
      t.string  :path
      t.text    :thumbnails
      t.timestamps
    end

    add_index :tr8n_media, [:owner_id, :owner_type, :keyword], :name => :tr8n_m_oid_ot_k
  end

  def down
    drop_table :tr8n_media
  end
end
