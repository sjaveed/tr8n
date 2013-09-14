class CreateDecorators < ActiveRecord::Migration
  def up
    create_table :tr8n_decorators do |t|
      t.integer   :application_id
      t.text      :css
      t.timestamps
    end

    add_index :tr8n_decorators, [:application_id], :name => :tr8n_decors_app
  end

  def down
    drop_table :tr8n_decorators
  end
end
