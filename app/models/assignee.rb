class Assignee < ApplicationRecord
  has_many :tasks
  has_many :vacations

  validates :name, uniqueness: true
  validates :email, uniqueness: true

  paginates_per 20
end
