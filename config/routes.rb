Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :assignees, only: [:index, :show]
  post 'assignees/retrieve_assignees'

  resources :projects, only: [:index, :show]
  post 'projects/retrieve_projects'

  resources :tasks, only: [:index, :show]
  post 'tasks/retrieve_tasks'
  post 'tasks/destroy_all'
end
