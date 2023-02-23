class Assignee < ApplicationRecord
  has_many :tasks

  validates :name, uniqueness: true
  validates :email, uniqueness: true

  paginates_per 10
end
