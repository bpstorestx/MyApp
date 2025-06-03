Rails.application.routes.draw do
  # User routes
  resources :users, only: [:new, :create]
  get 'signup', to: 'users#new', as: 'signup'
  
  # Session routes
  get 'login', to: 'sessions#new', as: 'login'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'
  
  # Account management routes
  get 'account', to: 'account#show', as: 'account'
  patch 'account/cancel_subscription', to: 'account#cancel_subscription', as: 'cancel_subscription'
  patch 'account/reactivate_subscription', to: 'account#reactivate_subscription', as: 'reactivate_subscription'
  
  # Subscription routes
  get 'subscribe', to: 'subscriptions#show', as: 'subscribe_page'
  post 'subscribe', to: 'subscriptions#create', as: 'subscribe'
  post 'webhooks/stripe', to: 'subscriptions#webhook'
  
  # Sidekiq Web UI
  require 'sidekiq/web'
  
  # No authentication for Sidekiq Web UI in development for easier access
  # In production, you might want to add authentication back
  mount Sidekiq::Web => '/sidekiq'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  resources :floorplans, only: [:index, :new, :create, :show] do
    member do
      get :sketch
      post :save_sketch
      get :custom_prompt
      post :save_custom_prompt
    end
    get :my_floorplans, on: :collection
  end
  root 'welcome#index'
end
