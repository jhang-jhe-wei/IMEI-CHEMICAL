class AddVisitedInComments < ActiveRecord::Migration[6.1]
  def change
    add_column :comments, :visited, :boolean, default: false
  end
end
