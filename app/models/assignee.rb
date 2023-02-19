class Assignee < ApplicationRecord
  has_many :tasks

  validates :name, uniqueness: true
  validates :email, uniqueness: true
end
