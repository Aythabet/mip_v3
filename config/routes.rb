require 'sidekiq/web'

Rails.application.routes.draw do

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  root to: "pages#home"
  get '/tests', to: 'pages#tests', as: 'tests', constraints: lambda { |request| request.env['warden'].user.admin? }


  # Assignees Routes
  resources :assignees, only: [:index, :show, :edit, :update] do
    post 'send_data_to_assignee', on: :member, as: :send_data_to_assignee
    resources :vacations, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  get '/assignee_profile/:id', to: 'assignees#assignee_profile', as: 'assignee_profile', constraints: lambda { |request| request.env['warden'].user.admin? }
  post 'assignees/retrieve_assignees'
  post 'assignees/destroy_all'


  # Projects Routes
  resources :projects do
    resources :quotes, only: [:new, :create, :index, :edit, :update]
  end

  get '/project_details/:id', to: 'projects#project_details', as: 'project_details', constraints: lambda { |request| request.env['warden'].user.admin? }

  post 'projects/retrieve_projects'
  post 'projects/destroy_all'

  # Tasks Routes
  resources :tasks, only: [:index]
  post 'tasks/retrieve_tasks'
  post 'tasks/destroy_all'

  # Admin Routes
  get '/all_vacations', to: 'admin#all_vacations', as: 'all_vacations', constraints: lambda { |request| request.env['warden'].user.admin? }

end
