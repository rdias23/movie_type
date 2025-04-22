require 'openai'
require 'json'

class OpenaiService
  def initialize
    puts "Initializing OpenAI service with key: #{ENV['OPENAI_API_KEY'].present? ? 'present' : 'missing'}"
    @client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end

  def generate_personality_description(movie_type)
    puts "Generating personality description for type: #{movie_type}"
    
    system_prompt = <<~PROMPT
      You are a poetic film critic with deep knowledge of cinema. Your task is to create an engaging, 
      insightful description of someone's movie-watching personality based on their 4-letter type.

      The type consists of 4 dimensions:
      1. P/A (Plot vs Atmosphere) - How they engage with narrative
      2. W/G (Whimsy vs Gravitas) - Their preferred emotional tone
      3. E/I (External vs Internal) - Their viewing perspective
      4. X/M (eXplicit vs aMbiguous) - Their interpretive approach

      So, a complete type might be something like PGEX AGIM

      Write a 2-3 paragraph response that:
      - Captures the essence of their cinematic personality
      - Uses elegant, poetic language
      - References their specific preferences without being too literal
      - Maintains a sophisticated, Criterion Collection-worthy tone
    PROMPT

    begin
      response = @client.chat(
        parameters: {
          model: ENV.fetch("OPENAI_MODEL", "gpt-4"),
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: "Generate a personality description for movie type: #{movie_type}" }
          ],
          temperature: 0.7
        }
      )
      puts "OpenAI response: #{response.inspect}"
      response.dig('choices', 0, 'message', 'content')
    rescue StandardError => e
      puts "OpenAI error in generate_personality_description: #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end

  def generate_recommendations(movie_type, responses)
    puts "\n\n=== GENERATING RECOMMENDATIONS ===\n"
    puts "Movie type: #{movie_type}"
    
    # Calculate average scores for context
    dimension_scores = responses.group_by { |r| r.quiz_question.personality_dimension }
                               .transform_values { |rs| rs.sum(&:response_value) / rs.size.to_f }
    
    puts "Dimension scores: #{dimension_scores.inspect}"

    system_prompt = <<~PROMPT
      You are a knowledgeable film curator with expertise across all genres and eras of cinema. 
      Based on the user's movie personality type and preferences, generate personalized film and director recommendations.

      The type #{movie_type} indicates these preferences:
      #{format_dimension_preferences(dimension_scores)}

      Return your response in this exact JSON format (no additional text or explanations):
      {
        "films": ["Film 1", "Film 2", "Film 3", "Film 4", "Film 5"],
        "directors": ["Director 1", "Director 2", "Director 3", "Director 4", "Director 5"]
      }

      Choose films and directors that match their preferences. Include both classics and lesser-known works.
      Focus on critically acclaimed choices that align with their personality type.
    PROMPT

    puts "\nSystem prompt:"
    puts system_prompt

    begin
      puts "\nCalling OpenAI API..."
      response = @client.chat(
        parameters: {
          model: ENV.fetch("OPENAI_MODEL", "gpt-4"),
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: "Generate recommendations for type: #{movie_type}" }
          ],
          temperature: 0.7
        }
      )
      puts "\nOpenAI API Response:"
      puts response.inspect
      
      # Parse the JSON response
      content = response.dig('choices', 0, 'message', 'content')
      puts "\nRaw content from OpenAI:"
      puts content.inspect
      
      begin
        puts "\nAttempting to parse JSON..."
        recommendations = JSON.parse(content)
        puts "Parsed recommendations: #{recommendations.inspect}"
        
        # Convert string keys to symbols and ensure we have the required keys
        result = {
          films: recommendations['films'] || [],
          directors: recommendations['directors'] || []
        }
        puts "\nProcessed result: #{result.inspect}"
        
        # If either array is empty, fall back to defaults
        if result[:films].empty? || result[:directors].empty?
          puts "\nMissing required recommendations, falling back to defaults"
          return generate_fallback_recommendations
        end
        
        result
      rescue JSON::ParserError => e
        puts "\nJSON parse error: #{e.message}"
        puts "Response was: #{content}"
        generate_fallback_recommendations
      end
    rescue StandardError => e
      puts "\nOpenAI error: #{e.message}\n#{e.backtrace.join("\n")}"
      generate_fallback_recommendations
    end
  end

  def generate_quote_for_type(movie_type, preferences)
    system_prompt = <<~PROMPT
      You are a film expert with deep knowledge of cinema. Generate a meaningful movie quote that reflects 
      this person's movie-watching personality. The quote can be from a real or imagined film, but it should 
      deeply resonate with their preferences.

      Their preferences are:
      #{preferences}

      Return a JSON response in this exact format:
      {
        "quote": "The quote text here",
        "attribution": "Character or Context, Movie Title"
      }

      The quote should feel authentic and meaningful, capturing the essence of their cinematic taste.
    PROMPT

    begin
      response = @client.chat(
        parameters: {
          model: ENV.fetch("OPENAI_MODEL", "gpt-4"),
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: "Generate a quote for movie type: #{movie_type}" }
          ],
          temperature: 0.7,
          response_format: { type: "json_object" }
        }
      )
      response.dig('choices', 0, 'message', 'content')
    rescue StandardError => e
      puts "OpenAI error in generate_quote: #{e.message}"
      fallback = { quote: "Every story is unique, just like every viewer.", attribution: "Movie Type" }
      fallback.to_json
    end
  end

  def all_personality_types(force_refresh: false)
    self.class.all_personality_types(force_refresh: force_refresh)
  end

  def self.all_personality_types(force_refresh: false)
    cache_key = "openai_service/personality_types"
    
    if force_refresh
      Rails.cache.delete(cache_key)
    end

    Rails.cache.fetch(cache_key, expires_in: 1.day) do
      dimensions = {
        narrative: ['P', 'A'],  # Plot vs Atmosphere
        tone: ['W', 'G'],      # Whimsy vs Gravitas
        perspective: ['E', 'I'], # External vs Internal
        interpretation: ['X', 'M']  # eXplicit vs aMbiguous
      }
      
      types = dimensions[:narrative].product(
        dimensions[:tone],
        dimensions[:perspective],
        dimensions[:interpretation]
      ).map { |combo| combo.join }

      types.each_with_object({}) do |type, hash|
        hash[type] = {
          dimensions: {
            narrative: type[0] == 'P' ? 'Plot-focused' : 'Atmosphere-focused',
            tone: type[1] == 'W' ? 'Whimsical' : 'Grave',
            perspective: type[2] == 'E' ? 'External' : 'Internal',
            interpretation: type[3] == 'X' ? 'Explicit' : 'Ambiguous'
          },
          description: OpenaiService.new.generate_personality_description(type)
        }
      end
    end
  end

  private

  def format_dimension_preferences(dimension_scores)
    dimension_scores.map do |dimension, score|
      preference = if score > 3
        "Strong preference for #{dimension.high_label}"
      elsif score < 3
        "Strong preference for #{dimension.low_label}"
      else
        "Balanced between #{dimension.high_label} and #{dimension.low_label}"
      end

      "- #{dimension.name}: #{preference}"
    end.join("\n")
  end

  def generate_fallback_recommendations
    puts "\nUsing fallback recommendations"
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
end
