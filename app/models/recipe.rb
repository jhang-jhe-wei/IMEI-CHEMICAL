class Recipe < ApplicationRecord
  has_many :recipe_items, dependent: :delete_all
end
