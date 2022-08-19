class RenameTypeInRecipeItems < ActiveRecord::Migration[6.1]
  def change
    rename_column :recipe_items, :type, :status
  end
end
