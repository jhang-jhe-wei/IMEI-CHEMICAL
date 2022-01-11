class CreateRecipeItems < ActiveRecord::Migration[6.1]
  def change
    create_table :recipe_items do |t|
      t.string :name
      t.decimal :weight
      t.decimal :unit_price
      t.decimal :price
      t.string :remark
      t.string :code
      t.references :recipe, null: false, foreign_key: true

      t.timestamps
    end
  end
end
