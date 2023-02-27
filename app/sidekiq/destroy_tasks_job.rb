class DestroyTasksJob
  include Sidekiq::Job

  def perform(*)
    Task.destroy_all
  end
end
