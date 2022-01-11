class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders do |t|
      t.string :custom_code
      t.date :printed_at
      t.string :name
      t.string :spec
      t.integer :quantity
      t.string :format
      t.string :address

      t.timestamps
    end
  end
end
