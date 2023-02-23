class Task < ApplicationRecord
  belongs_to :project
  belongs_to :assignee

  paginates_per 9
end
