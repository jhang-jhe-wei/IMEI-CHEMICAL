Rails.application.routes.draw do
  namespace :admin do
      resources :users
      resources :recipes
      resources :recipe_items
      resources :stock_units
      resources :orders
      resources :comments
      post "comments/visited", to: "comments#visited"
      root to: "recipes#index"
    end
  root to: "landings#index"
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
