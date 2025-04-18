class ResultPresenter
  attr_reader :user_email, :movie_type, :personality_description, :recommendations

  def initialize(user_email)
    @user_email = user_email
    calculate_results
  end

  def calculate_results
    @movie_type = calculate_movie_type
    openai = OpenaiService.new
    @personality_description = openai.generate_personality_description(@movie_type)
    @recommendations = openai.generate_recommendations(@movie_type, user_responses)
  end

  private

  def calculate_movie_type
    # Get all responses for this user
    responses = user_responses
    return nil if responses.empty?

    # Group responses by dimension and calculate letters
    type_letters = PersonalityDimension.all.map do |dimension|
      dimension_responses = responses.select { |r| r.quiz_question.personality_dimension_id == dimension.id }
      dimension.calculate_letter(dimension_responses)
    end

    # Combine letters into final type
    type_letters.join
  end

  def user_responses
    @user_responses ||= UserResponse.where(user_email: user_email)
  end

  # Helper methods for the view
  def dimension_breakdowns
    PersonalityDimension.all.map do |dimension|
      responses = user_responses.select { |r| r.quiz_question.personality_dimension_id == dimension.id }
      avg_score = responses.empty? ? 3 : responses.average(:response_value).to_f
      
      {
        name: dimension.name,
        score: avg_score,
        letter: dimension.calculate_letter(responses),
        high_label: dimension.high_label,
        low_label: dimension.low_label
      }
    end
  end
end
