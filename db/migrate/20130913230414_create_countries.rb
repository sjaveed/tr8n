class CreateCountries < ActiveRecord::Migration
  def up
    create_table :tr8n_countries do |t|
      t.string  :code
      t.string  :english_name
      t.string  :native_name
      t.string  :telephone_code
      t.string  :currency
      t.timestamps
    end

    add_index :tr8n_countries, [:code], :name => :tr8n_countries_code
  end

  def down
    drop_table :tr8n_countries
  end
end
