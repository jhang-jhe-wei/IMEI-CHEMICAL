class LandingsController < ApplicationController
  Admin_roles = ["admin"]
  def index
    @user_count = User.count
    @admin_count = User.where(role: Admin_roles).count
    @recipe_count = Recipe.count
    @recipe_items_count = RecipeItem.count
    @comment_count = Comment.count
  end
end
