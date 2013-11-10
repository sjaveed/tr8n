class AddDescriptionAndExamplesToLanguageRules < ActiveRecord::Migration
  def change
    add_column :tr8n_language_rules, :description, :string
    add_column :tr8n_language_rules, :examples, :string

    add_column :tr8n_language_case_rules, :description, :string
    add_column :tr8n_language_case_rules, :examples, :string
  end
end
