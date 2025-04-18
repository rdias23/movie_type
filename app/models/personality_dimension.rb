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
    score >= 3 ? high_label[0].upcase : low_label[0].upcase
  end

  # Calculate the letter for a set of responses
  def calculate_letter(responses)
    return nil if responses.empty?
    
    # Calculate average score for this dimension
    avg_score = if responses.respond_to?(:average)
      responses.average(:response_value).to_f
    else
      responses.sum(&:response_value).to_f / responses.length
    end

    Rails.logger.debug("Dimension #{name}: #{responses.length} responses, avg_score: #{avg_score}")
    self.class.score_to_letter(avg_score, high_label, low_label)
  end

  # Returns the letter code for this dimension based on the aggregate response
  def letter_for_score(score)
    self.class.score_to_letter(score, high_label, low_label)
  end
end
