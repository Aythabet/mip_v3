class Project < ApplicationRecord
  has_many :tasks
  has_many :quotes, dependent: :destroy
  paginates_per 20

end
