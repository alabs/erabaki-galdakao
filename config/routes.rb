# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  mount Decidim::Core::Engine => "/"
  mount Decidim::FileAuthorizationHandler::AdminEngine => "/admin"

  namespace :admin do
    # Rutas del panel de gestión de calles de Galdakao
    resources :galdakao, only: [:index] do
      collection do
        get  :streets   # JSON endpoint para el select2 + vista HTML del listado
        post :sync      # Lanza la sincronización de calles desde la API
        post :check     # Comprueba un DNI/fecha contra el webservice (debug)
      end
    end
  end
end