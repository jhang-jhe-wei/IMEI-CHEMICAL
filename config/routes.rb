Rails.application.routes.draw do
  namespace :admin do
      resources :users
      resources :recipes
      resources :stock_units
      resources :orders
      resources :comments
      resources :recipe_items

      root to: "users#index"
    end
  root to: "landings#index"
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
