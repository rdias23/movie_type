class PersonalityDimension < ApplicationRecord
  has_many :quiz_questions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :high_label, :low_label, presence: true
  validates :description, presence: true, length: { minimum: 10 }

  # Returns the letter code for this dimension based on the aggregate response
  def letter_for_score(score)
    score >= 0 ? high_label.first.upcase : low_label.first.upcase
  end
end
