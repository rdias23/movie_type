class PersonalityDimension < ApplicationRecord
  has_many :quiz_questions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :high_label, :low_label, presence: true
  validates :description, presence: true, length: { minimum: 10 }

  # Convert numerical scores to dimension letters
  def self.score_to_letter(score, high_label, low_label)
    # Score is on a 1-5 scale, where:
    # 1-2 = strongly/somewhat prefer low_label
    # 3 = neutral
    # 4-5 = somewhat/strongly prefer high_label
    # We'll use the first letter of each label
    score >= 3 ? high_label[0] : low_label[0]
  end

  # Calculate the letter for a set of responses
  def calculate_letter(responses)
    return nil if responses.empty?
    
    # Calculate average score for this dimension
    avg_score = responses.average(:response_value).to_f
    self.class.score_to_letter(avg_score, high_label, low_label)
  end

  # Returns the letter code for this dimension based on the aggregate response
  def letter_for_score(score)
    score >= 0 ? high_label.first.upcase : low_label.first.upcase
  end
end
