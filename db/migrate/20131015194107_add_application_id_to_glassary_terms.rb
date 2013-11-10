class AddApplicationIdToGlassaryTerms < ActiveRecord::Migration
  def change
    add_column :tr8n_glossary, :application_id, :integer
    add_column :tr8n_glossary, :language_id, :integer

    add_index :tr8n_glossary, [:application_id], :name => :tr8n_g_a
  end
end
