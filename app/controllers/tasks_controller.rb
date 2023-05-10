class TasksController < ApplicationController
  def index
    breadcrumbs.add "Tasks", tasks_path

    @tasks = Task.order(updated_at: :desc)
    @tasks = @tasks.page params[:page]

    if turbo_frame_request?
      render partial: "tasks", locals: { tasks: @tasks }
    else
      render :index
    end

    @tasks_count = Task.count
  end

  def retrieve_tasks
    TasksJob.perform_async

    flash.notice = "The import started, come back in few minutes!"
    redirect_to tasks_path
  end

  def destroy_all
    DestroyTasksJob.perform_async

    flash.notice = "All the tasks will be deleted."
    redirect_to tasks_path
  end

  def show
    @task = Task.find(params[:id])
    @task_changelog = TaskChangelog.where(task_id: @task.id).order(created_at: :desc)
    @task_worklog = TaskWorklog.where(task_id: @task.id).order(created_at: :desc)
  end
end
