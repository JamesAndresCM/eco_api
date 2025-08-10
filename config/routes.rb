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
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
