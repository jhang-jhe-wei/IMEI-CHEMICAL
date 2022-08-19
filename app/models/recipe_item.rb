class RecipeItem < ApplicationRecord
  belongs_to :recipe
  has_one_attached :proof_pdf
  has_one_attached :picture
end
