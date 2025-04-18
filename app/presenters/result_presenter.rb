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
    
    if ENV['OPENAI_API_KEY'].present?
      Rails.logger.info "Attempting to use OpenAI..."
      begin
        openai = OpenaiService.new
        Rails.logger.info "OpenAI service initialized"
        
        @personality_description = openai.generate_personality_description(@movie_type)
        Rails.logger.info "Got personality description: #{@personality_description}"
        
        @recommendations = openai.generate_recommendations(@movie_type, user_responses)
        Rails.logger.info "Got recommendations: #{@recommendations.inspect}"
      rescue StandardError => e
        Rails.logger.error "Error using OpenAI: #{e.message}\n#{e.backtrace.join("\n")}"
        Rails.logger.info "Falling back to default content..."
        @personality_description = archetype[:description]
        @recommendations = generate_fallback_recommendations
      end
    else
      Rails.logger.info "No OpenAI key, using fallback content"
      @personality_description = archetype[:description]
      @recommendations = generate_fallback_recommendations
    end
  rescue StandardError => e
    Rails.logger.error("Error in ResultPresenter: #{e.message}")
    @personality_description = generate_fallback_description
    @recommendations = generate_fallback_recommendations
  end

  def dimension_breakdowns
    Rails.logger.info("Calculating dimension breakdowns...")
    Rails.logger.info("User responses: #{user_responses.inspect}")
    Rails.logger.info("Personality dimensions: #{PersonalityDimension.all.inspect}")

    PersonalityDimension.all.map do |dimension|
      dimension_responses = user_responses.select { |r| r.quiz_question.personality_dimension_id == dimension.id }
      avg_score = dimension_responses.empty? ? 3 : dimension_responses.sum(&:response_value).to_f / dimension_responses.length
      
      Rails.logger.info("Dimension #{dimension.name}: #{dimension_responses.length} responses, avg_score: #{avg_score}")
      
      {
        name: dimension.name,
        score: avg_score,
        letter: dimension.calculate_letter(dimension_responses),
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
    return "????" if responses.empty?

    # Group responses by dimension and calculate letters
    type_letters = PersonalityDimension.all.map do |dimension|
      dimension_responses = responses.select { |r| r.quiz_question.personality_dimension_id == dimension.id }
      dimension.calculate_letter(dimension_responses) || "?"
    end

    # Combine letters into final type
    type_letters.join
  end

  def user_responses
    @user_responses ||= UserResponse.includes(quiz_question: :personality_dimension)
                                  .where(user_email: user_email)
  end
end
