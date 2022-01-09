class RemoveTagInComments < ActiveRecord::Migration[6.1]
  def change
    remove_column :comments, :tag
  end
end
