require "sidekiq/web"

Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, controllers: {
                       omniauth_callbacks: "users/omniauth_callbacks",
                       sessions: "users/sessions",
                       registrations: "users/registrations",
                     }

  root to: "pages#home"

  # Assignees Routes
  resources :assignees, only: [:index, :show, :edit, :update] do
    post "send_data_to_assignee", on: :member, as: :send_data_to_assignee
    post "generate_pdf_report", on: :collection
    resources :vacations, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  get "/assignee_profile/:id", to: "assignees#assignee_profile", as: "assignee_profile", constraints: lambda { |request| request.env["warden"].user.admin? }
  post "assignees/retrieve_assignees"

  # Projects Routes
  resources :projects do
    resources :quotes, only: [:new, :create, :index, :edit, :update]
    post "generate_pdf_report", on: :collection
    member do
      post "update_project_status", to: "projects#update_project_status"
    end
  end

  get "/project_details/:id", to: "projects#project_details", as: "project_details", constraints: lambda { |request| request.env["warden"].user.admin? }

  # Tasks Routes
  resources :tasks, only: [:index, :show]

  # Admin Routes
  resources :admin, only: [:index]

  post "admin/db_task_cleaner"
  post "admin/retrieve_tasks"
  post "admin/destroy_all"
  get "/all_vacations", to: "admin#all_vacations", as: "all_vacations", constraints: lambda { |request| request.env["warden"].user.admin? }
  get "/flagged_tasks", to: "admin#flagged_tasks", as: "flagged_tasks", constraints: lambda { |request| request.env["warden"].user.admin? }
  get "/sidekiq_logs", to: "admin#sidekiq_logs", as: "sidekiq_logs", constraints: lambda { |request| request.env["warden"].user.admin? }
  post "start_slack_message_job/:task_id", to: "admin#start_slack_message_job", as: "start_slack_message_job"
  post "start_jira_issue_comment_job/:task_id", to: "admin#start_jira_issue_comment_job", as: "start_jira_issue_comment_job"
end
