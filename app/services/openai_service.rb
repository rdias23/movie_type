require 'openai'

class OpenaiService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end

  def generate_personality_description(movie_type)
    system_prompt = <<~PROMPT
      You are a poetic film critic with deep knowledge of cinema. Your task is to create an engaging, 
      insightful description of someone's movie-watching personality based on their 4-letter type.

      The type consists of 4 dimensions:
      1. P/A (Plot vs Atmosphere) - How they engage with narrative
      2. W/G (Whimsy vs Gravitas) - Their preferred emotional tone
      3. E/I (External vs Internal) - Their viewing perspective
      4. X/M (eXplicit vs aMbiguous) - Their interpretive approach

      Write a 2-3 paragraph response that:
      - Captures the essence of their cinematic personality
      - Uses elegant, poetic language
      - References their specific preferences without being too literal
      - Maintains a sophisticated, Criterion Collection-worthy tone
    PROMPT

    response = @client.chat(
      parameters: {
        model: 'gpt-4',
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: "Generate a personality description for movie type: #{movie_type}" }
        ],
        temperature: 0.7
      }
    )

    response.dig('choices', 0, 'message', 'content')
  end

  def generate_recommendations(movie_type, responses)
    # Calculate average scores for context
    dimension_scores = responses.group_by { |r| r.quiz_question.personality_dimension }
                               .transform_values { |rs| rs.average(:response_value).to_f }

    system_prompt = <<~PROMPT
      You are a knowledgeable film curator with expertise across all genres and eras of cinema. 
      Your task is to recommend films and directors based on someone's movie personality type 
      and their specific response patterns.

      The type #{movie_type} indicates these preferences:
      #{format_dimension_preferences(dimension_scores)}

      Provide recommendations in this format:
      1. Three essential films that epitomize this type
      2. Three directors whose work consistently matches these preferences
      3. One "stretch" recommendation that might push their boundaries while still appealing to their tastes

      For each recommendation, include a brief, elegant explanation of why it matches their profile.
      Focus on lesser-known or critically acclaimed works rather than obvious mainstream choices.
    PROMPT

    response = @client.chat(
      parameters: {
        model: 'gpt-4',
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: "Generate recommendations for type: #{movie_type}" }
        ],
        temperature: 0.7
      }
    )

    response.dig('choices', 0, 'message', 'content')
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
end
