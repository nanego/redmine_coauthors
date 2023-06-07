class AddCoauthorsToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :coauthors_status, :integer, :default => 0
    add_column :issues, :coauthors_organization_id, :integer, :default => nil
  end
end
