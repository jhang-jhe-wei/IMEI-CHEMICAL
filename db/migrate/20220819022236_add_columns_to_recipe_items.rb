class AddColumnsToRecipeItems < ActiveRecord::Migration[6.1]
  def change
    remove_column :recipe_items, :weight
    remove_column :recipe_items, :unit_price
    remove_column :recipe_items, :price
    remove_column :recipe_items, :code
    add_column :recipe_items, :category, :string
    add_column :recipe_items, :qty, :string
    add_column :recipe_items, :assays, :string
    add_column :recipe_items, :melting_point, :string
    add_column :recipe_items, :type, :string
    add_column :recipe_items, :expression, :string
  end
end
