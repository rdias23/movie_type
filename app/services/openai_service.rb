require 'openai'

class OpenaiService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end

  def generate_personality_description(movie_type)
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

  def generate_recommendations(movie_type, preferences)
    response = @client.chat(
      parameters: {
        model: 'gpt-4',
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: "Generate film and director recommendations for movie type: #{movie_type}, with preferences: #{preferences}" }
        ],
        temperature: 0.7
      }
    )

    response.dig('choices', 0, 'message', 'content')
  end

  private

  def system_prompt
    <<~PROMPT
      You are a sophisticated film critic and cinema expert with deep knowledge of film history, 
      theory, and cultural impact. Your task is to analyze movie preferences and create 
      insightful, poetic descriptions of viewing personalities while recommending films 
      that would resonate with each type.

      When describing personalities:
      - Use elegant, expressive language that evokes the Criterion Collection's tone
      - Reference specific film movements, directors, and artistic approaches
      - Balance accessibility with sophisticated film knowledge
      - Create memorable, poetic descriptions that illuminate the viewer's relationship with cinema

      When making recommendations:
      - Suggest both accessible entry points and more challenging deep cuts
      - Include a mix of eras and national cinemas
      - Explain briefly why each recommendation fits the viewer's type
      - Focus on films that will expand their appreciation while staying within their comfort zone
    PROMPT
  end
end
