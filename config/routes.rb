# frozen_string_literal: true

Rails.application.routes.draw do
  # Configuración de Devise
  devise_for :users, skip: :all

  # Rutas de autenticación
  devise_scope :user do
    namespace :auth do
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"
      post "register", to: "registrations#create"
      post "forgot_password", to: "passwords#create"
      patch "change_password", to: "passwords#update"
      put "change_password", to: "passwords#update"
      post "refresh_tokens", to: "refresh_tokens#create"
    end
  end

  # API Routes
  namespace :api do
    namespace :v1 do
      namespace :users do
        get "me", to: "profile#me"
      end
      namespace :payments do
        get "webpay-plus/create", to: "webpay_plus#create", as: :webpay_plus_create
        match "webpay-plus/commit", to: "webpay_plus#commit",  via: %i[get post], as: :webpay_plus_commit
        post "webpay-plus/:id/retry", to: "webpay_plus#retry", as: :webpay_plus_retry
        get   "webpay-plus/refund",  to: "webpay_plus#refund",  as: :webpay_plus_refund
        get   "webpay-plus/status",  to: "webpay_plus#status",  as: :webpay_plus_status
      end
      resources :products, only: %i[index show]
      resources :orders,   only: %i[index show create]
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  mount MissionControl::Jobs::Engine, at: "/jobs" if Rails.env.development?
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # Authenticated users go to their profile, others see API info
  authenticated :user do
    root "api/v1/users/profile#me", as: :authenticated_root
  end

  root "info#index"

  # Catch-all for non-GET requests to root
  match "/", to: "info#index", via: %i[post put patch delete]

  # Catch-all route for undefined endpoints
  match "*path", to: "application#render_not_found", via: :all
end
