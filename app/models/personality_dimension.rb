class PersonalityDimension < ApplicationRecord
  has_many :quiz_questions

  validates :name, presence: true
  validates :high_label, presence: true
  validates :low_label, presence: true

  def letter_for_score(normalized_score)
    self.class.score_to_letter(normalized_score, high_label, low_label)
  end

  def self.score_to_letter(normalized_score, high_label, low_label)
    # A score of -1.0 means strongly prefer first option (high_label)
    # A score of 0.0 means neutral between options (default to high_label)
    # A score of 1.0 means strongly prefer second option (low_label)
    normalized_score >= 0.5 ? low_label[0].upcase : high_label[0].upcase
  end

  def calculate_letter(responses)
    normalized_scores = responses.map { |r| r.quiz_question.normalize_response(r.response_value) }
    avg_normalized = normalized_scores.sum / normalized_scores.length
    Rails.logger.info("Dimension #{name}:")
    Rails.logger.info("  Responses: #{responses.map(&:response_value)}")
    Rails.logger.info("  Normalized: #{normalized_scores}")
    Rails.logger.info("  Average: #{avg_normalized}")
    letter_for_score(avg_normalized)
  end
end
