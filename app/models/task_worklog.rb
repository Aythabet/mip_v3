class TaskWorklog < ApplicationRecord
  belongs_to :task

  validates :worklog_entry_id, presence: true, uniqueness: true
end
