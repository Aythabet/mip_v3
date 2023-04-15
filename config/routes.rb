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

  resources :assignees, only: [:index, :show, :edit, :update] do
    post 'send_data_to_assignee', on: :member, as: :send_data_to_assignee
  end

  get '/assignee_profile/:id', to: 'assignees#assignee_profile', as: 'assignee_profile'
  post 'assignees/retrieve_assignees'
  post 'assignees/destroy_all'

  resources :projects, only: [:index, :show]
  get '/project_details/:id', to: 'projects#project_details', as: 'project_details'
  post 'projects/retrieve_projects'
  post 'projects/destroy_all'

  resources :tasks, only: [:index]
  post 'tasks/retrieve_tasks'
  post 'tasks/destroy_all'
end
