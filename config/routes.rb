require 'sidekiq/web'

Rails.application.routes.draw do

  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  root to: "pages#home"

  resources :assignees, only: [:index, :show] do
    post 'send_data_to_assignee', on: :member, as: :send_data_to_assignee
  end

  post 'assignees/retrieve_assignees'
  post 'assignees/destroy_all'

  resources :projects, only: [:index, :show]
  post 'projects/retrieve_projects'
  post 'projects/destroy_all'

  resources :tasks, only: [:index]
  post 'tasks/retrieve_tasks'
  post 'tasks/destroy_all'
end
