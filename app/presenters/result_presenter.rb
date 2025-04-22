class ResultPresenter
  attr_reader :user_email, :movie_type, :personality_description, :recommendations, :archetype_title

  def initialize(user_email)
    @user_email = user_email
    calculate_results
  end

  def calculate_results
    @movie_type = calculate_movie_type
    archetype = PersonalityArchetypeService.get_archetype(@movie_type)
    @archetype_title = archetype[:title]
    
    # Fallback descriptions if OpenAI is not configured
    Rails.logger.info "OPENAI_API_KEY present?: #{ENV['OPENAI_API_KEY'].present?}"
    
    begin
      if ENV['OPENAI_API_KEY'].present?
        openai = OpenaiService.new
        Rails.logger.info "OpenAI service initialized"
        
        @personality_description = openai.generate_personality_description(@movie_type)
        Rails.logger.info "Got personality description: #{@personality_description}"
        
        @recommendations = openai.generate_recommendations(@movie_type, user_responses)
        Rails.logger.info "Got recommendations: #{@recommendations.inspect}"
      end
    rescue StandardError => e
      Rails.logger.error "Error using OpenAI: #{e.message}\n#{e.backtrace.join("\n")}"
      Rails.logger.info "Falling back to default content..."
      @personality_description = generate_fallback_description
      @recommendations = generate_fallback_recommendations
    end
  end

  def dimension_breakdowns
    Rails.logger.info("Calculating dimension breakdowns...")
    Rails.logger.info("User responses: #{user_responses.inspect}")
    Rails.logger.info("Personality dimensions: #{PersonalityDimension.all.inspect}")

    PersonalityDimension.all.map do |dimension|
      dimension_responses = user_responses.select { |r| r.quiz_question.personality_dimension_id == dimension.id }
      
      # Calculate normalized scores for both letter and meter
      normalized_scores = dimension_responses.map { |r| r.quiz_question.normalize_response(r.response_value) }
      avg_normalized = normalized_scores.sum / normalized_scores.length
      
      Rails.logger.info("\nDimension: #{dimension.name}")
      Rails.logger.info("Raw responses: #{dimension_responses.map(&:response_value)}")
      Rails.logger.info("Normalized scores: #{normalized_scores}")
      Rails.logger.info("Average normalized: #{avg_normalized}")
      
      letter = dimension.letter_for_score(avg_normalized)
      Rails.logger.info("Final letter: #{letter}")
      
      {
        name: dimension.name,
        normalized_scores: normalized_scores,  # Pass normalized scores to view
        avg_normalized: avg_normalized,  # Pass pre-calculated average
        letter: letter,
        high_label: dimension.high_label,
        low_label: dimension.low_label
      }
    end
  rescue StandardError => e
    Rails.logger.error("Error calculating dimension breakdowns: #{e.message}\n#{e.backtrace.join("\n")}")
    []
  end

  private

  def generate_fallback_description
    archetype = PersonalityArchetypeService.get_archetype(@movie_type)
    archetype[:description]
  end

  def generate_fallback_recommendations
    {
      films: [
        "2001: A Space Odyssey",
        "The Godfather",
        "Pulp Fiction",
        "Amélie",
        "Seven Samurai"
      ],
      directors: [
        "Stanley Kubrick",
        "Martin Scorsese",
        "Akira Kurosawa",
        "Wong Kar-wai",
        "Christopher Nolan"
      ]
    }
  end

  def calculate_movie_type
    # Get all responses for this user
    responses = user_responses
    
    # Group responses by dimension and calculate letters
    type_letters = PersonalityDimension.all.map do |dimension|
      dimension_responses = responses.select { |r| r.quiz_question.personality_dimension_id == dimension.id }
      
      # Calculate normalized scores
      normalized_scores = dimension_responses.map { |r| r.quiz_question.normalize_response(r.response_value) }
      avg_normalized = normalized_scores.sum / normalized_scores.length
      
      Rails.logger.info("\nCalculating letter for dimension #{dimension.name}:")
      Rails.logger.info("  Raw responses: #{dimension_responses.map(&:response_value)}")
      Rails.logger.info("  Normalized scores: #{normalized_scores}")
      Rails.logger.info("  Average normalized: #{avg_normalized}")
      
      letter = dimension.letter_for_score(avg_normalized)
      Rails.logger.info("  Letter: #{letter}")
      letter
    end

    type_letters.join
  end

  def user_responses
    @user_responses ||= UserResponse.includes(quiz_question: :personality_dimension)
                                  .where(user_email: user_email)
  end
end
