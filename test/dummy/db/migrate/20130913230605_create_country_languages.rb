class CreateCountryLanguages < ActiveRecord::Migration
  def up
    create_table :tr8n_country_languages do |t|
      t.integer :position
      t.integer :country_id
      t.integer :language_id
      t.boolean :official
      t.boolean :primary
      t.integer :population
      t.timestamps
    end

    add_index :tr8n_country_languages, [:country_id], :name => :tr8n_cl_cid
    add_index :tr8n_country_languages, [:language_id], :name => :tr8n_cl_lid
  end

  def down
    drop_table :tr8n_country_languages
  end
end
