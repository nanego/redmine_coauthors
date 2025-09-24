class AddMissingIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :issues, :coauthors_organization_id, if_not_exists: true
    add_index :issues, [:coauthors_organization_id, :coauthors_status], if_not_exists: true
  end
end
