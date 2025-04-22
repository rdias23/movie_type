class PersonalityDimension < ApplicationRecord
  has_many :quiz_questions

  validates :name, presence: true
  validates :high_label, presence: true
  validates :low_label, presence: true

  def letter_for_score(normalized_score)
    self.class.score_to_letter(normalized_score, high_label, low_label)
  end

  def self.score_to_letter(normalized_score, high_label, low_label)
    # A score of 1 means strongly prefer first option (low_label)
    # A score of 5 means strongly prefer second option (high_label)
    # For alternating responses (1,5,1,5), the average will be 3,
    # which gives normalized_score of 0, defaulting to high_label
    # We should instead look at the absolute values to detect mixed preferences
    if normalized_score.abs < 0.3 # If close to center, it's truly mixed
      '?' # Indicate uncertainty
    else
      normalized_score <= 0 ? high_label[0].upcase : low_label[0].upcase
    end
  end

  def calculate_letter(responses)
    normalized_scores = responses.map { |r| r.quiz_question.normalize_response(r.response_value) }
    
    # Check if responses are mixed (alternating between extremes)
    # If we have strong opinions in both directions, it's mixed
    strong_high = normalized_scores.any? { |s| s > 0.5 }  # Strong preference for high
    strong_low = normalized_scores.any? { |s| s < -0.5 }  # Strong preference for low
    
    if strong_high && strong_low
      '?' # Mixed preference
    else
      avg_normalized = normalized_scores.sum / normalized_scores.length
      Rails.logger.info("Dimension #{name}:")
      Rails.logger.info("  Responses: #{responses.map(&:response_value)}")
      Rails.logger.info("  Normalized: #{normalized_scores}")
      Rails.logger.info("  Average: #{avg_normalized}")
      letter_for_score(avg_normalized)
    end
  end
end
