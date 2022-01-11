class CreateStockUnits < ActiveRecord::Migration[6.1]
  def change
    create_table :stock_units do |t|
      t.string :name
      t.string :spec
      t.string :code
      t.string :format
      t.decimal :quantity

      t.timestamps
    end
  end
end
