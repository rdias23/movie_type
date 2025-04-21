class UserResponse < ApplicationRecord
  belongs_to :quiz_question

  validates :user_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :response_value, presence: true, inclusion: { in: 1..5 }
  
  # Get the normalized score for this response (-1.0 to 1.0)
  def normalized_score
    quiz_question.normalize_response(response_value)
  end

  # Class method to calculate a user's complete movie personality type
  def self.calculate_type(user_email)
    return nil unless user_email.present?

    # Group responses by personality dimension and calculate average scores
    dimension_scores = joins(quiz_question: :personality_dimension)
      .where(user_email: user_email)
      .group('personality_dimensions.id')
      .select('personality_dimensions.*, AVG(user_responses.response_value - 3) as avg_score')
      .order('personality_dimensions.id')

    # Convert scores to letters
    dimension_scores.map do |result|
      result.letter_for_score(result.avg_score)
    end.join
  end

  # Safe method to view user email for debugging
  def self.debug_responses_for_email(email)
    Rails.logger.info "DEBUGGING: Viewing responses for #{email}"
    where(user_email: email).includes(:quiz_question).map do |response|
      {
        email: response.user_email,
        question_id: response.quiz_question_id,
        value: response.response_value,
        created_at: response.created_at
      }
    end
  end
end
