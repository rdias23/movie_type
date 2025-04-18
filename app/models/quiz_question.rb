class QuizQuestion < ApplicationRecord
  belongs_to :personality_dimension
  has_many :user_responses, dependent: :destroy

  validates :prompt, presence: true
  validates :high_text, :low_text, presence: true

  # Convert a user's response (typically 1-5) to a normalized score (-1.0 to 1.0)
  def normalize_response(response_value)
    return 0 unless response_value.between?(1, 5)
    (response_value - 3) / 2.0
  end
end
