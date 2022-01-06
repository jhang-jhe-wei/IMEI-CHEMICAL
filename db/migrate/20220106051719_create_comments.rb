class CreateComments < ActiveRecord::Migration[6.1]
  def change
    create_table :comments do |t|
      t.string :name
      t.string :category
      t.string :tag
      t.integer :price
      t.string :context
      t.string :user_name
      t.datetime :posted_time
      t.string :source_url
      t.string :source_type

      t.timestamps
    end
  end
end
