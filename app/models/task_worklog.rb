class TaskWorklog < ApplicationRecord
  belongs_to :task

  validates :worklog_entry_id, presence: true, uniqueness: true
  after_create :generate_sentence_attribute

  private

  def generate_sentence_attribute
    self.update(sentence:"#{task_id} - #{status}: #{author} logged #{duration} at #{created}.")
  end

end
