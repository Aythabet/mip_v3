class Project < ApplicationRecord
  has_many :tasks

  paginates_per 20

end
