class TasksController < ApplicationController
  def index
    breadcrumbs.add "Tasks", tasks_path

    @tasks = Task.order(updated_at: :desc).page(params[:page])

    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @tasks = @tasks.where(last_jira_update: start_date..end_date)
    end

    if params[:assignee].present?
      assignee_id = Assignee.find_by(name: params[:assignee]).id
      @tasks = @tasks.where(assignee: assignee_id)
    end

    @tasks_count = Task.count

    if turbo_frame_request?
      render partial: "tasks", locals: { tasks: @tasks }
    else
      render :index
    end
  end

  def show
    @task = Task.find(params[:id])
    @task_changelog = TaskChangelog.where(task_id: @task.id).order(created_at: :desc)
    @task_worklog = TaskWorklog.where(task_id: @task.id).order(created_at: :desc)
  end
end
