class Task < ApplicationRecord
  belongs_to :project
  belongs_to :assignee
  has_many :task_worklogs

  paginates_per 15

  def calculate_due_date
    return if due_date.present? || self.time_forecast.nil? || self.status_change_date.nil?

    total_seconds = time_forecast.to_i
    days = (total_seconds / (8 * 60 * 60)).to_i
    remaining_seconds = total_seconds % (8 * 60 * 60)

    date = status_change_date.to_date

    # Add business days to the date
    while days > 0 || date.saturday? || date.sunday?
      date += 1.day
      days -= 1 unless date.saturday? || date.sunday?
    end

    # Add remaining seconds
    date += remaining_seconds.seconds

    update(due_date: date)
  end

  before_save :calculate_due_date
  before_update :calculate_due_date
end
