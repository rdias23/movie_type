class QuizQuestion < ApplicationRecord
  belongs_to :personality_dimension
  has_many :user_responses, dependent: :destroy

  validates :prompt, presence: true
  validates :high_text, :low_text, presence: true

  # Convert a user's response (typically 1-5) to a normalized score (-1.0 to 1.0)
  # 1 = Strongly prefer first option (low_text) -> becomes -1.0
  # 3 = Neutral -> becomes 0.0
  # 5 = Strongly prefer second option (high_text) -> becomes 1.0
  def normalize_response(response_value)
    return 0 unless response_value.between?(1, 5)
    # Normalize to -1.0 to 1.0 range
    # This maps:
    # 1 -> -1.0 (strong low preference)
    # 2 -> -0.5
    # 3 -> 0.0 (neutral)
    # 4 -> 0.5
    # 5 -> 1.0 (strong high preference)
    (response_value - 3) / 2.0
  end
end
