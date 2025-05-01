require 'rails_helper'

RSpec.describe OpenaiService do
  let(:service) { OpenaiService.new }
  let(:movie_type) { 'PWEX' }
  let(:personality_dimension) { create(:personality_dimension,
    name: 'Narrative',
    high_label: 'Plot',
    low_label: 'Atmosphere'
  )}
  let(:quiz_question) { create(:quiz_question,
    personality_dimension: personality_dimension,
    prompt: 'Test question?'
  )}
  let(:user_response) { create(:user_response,
    quiz_question: quiz_question,
    response_value: 4
  )}

  describe '#initialize' do
    context 'when OPENAI_API_KEY is present' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_API_KEY').and_return('test-key')
      end

      it 'initializes the OpenAI client' do
        expect(OpenAI::Client).to receive(:new).with(access_token: 'test-key')
        OpenaiService.new
      end
    end

    context 'when OPENAI_API_KEY is missing' do
      before do
        allow(ENV).to receive(:fetch).with('OPENAI_API_KEY').and_raise(KeyError)
      end

      it 'raises a KeyError' do
        expect { OpenaiService.new }.to raise_error(KeyError)
      end
    end
  end

  describe '#generate_personality_description' do
    let(:mock_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => 'Test personality description'
            }
          }
        ]
      }
    end

    before do
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(mock_response)
    end

    it 'generates a personality description' do
      result = service.generate_personality_description(movie_type)
      expect(result).to eq('Test personality description')
    end

    it 'uses the correct system prompt' do
      expect_any_instance_of(OpenAI::Client).to receive(:chat) do |_, params|
        system_message = params[:parameters][:messages].first
        expect(system_message[:role]).to eq('system')
        expect(system_message[:content]).to include('You are a poetic film critic')
        mock_response
      end
      service.generate_personality_description(movie_type)
    end

    context 'when API call fails' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(StandardError)
      end

      it 'raises the error' do
        expect { service.generate_personality_description(movie_type) }.to raise_error(StandardError)
      end
    end
  end

  describe '#generate_recommendations' do
    let(:mock_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => {
                films: ['Test Film'],
                directors: ['Test Director']
              }.to_json
            }
          }
        ]
      }
    end

    before do
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(mock_response)
    end

    it 'generates recommendations' do
      result = service.generate_recommendations(movie_type, [user_response])
      expect(result).to include(:films, :directors)
    end

    context 'when API returns invalid JSON' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return({
          'choices' => [{ 'message' => { 'content' => 'Invalid JSON' } }]
        })
      end

      it 'returns fallback recommendations' do
        result = service.generate_recommendations(movie_type, [user_response])
        expect(result[:films]).to include('2001: A Space Odyssey')
        expect(result[:directors]).to include('Stanley Kubrick')
      end
    end

    context 'when API call fails' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(StandardError)
      end

      it 'returns fallback recommendations' do
        result = service.generate_recommendations(movie_type, [user_response])
        expect(result[:films]).to include('2001: A Space Odyssey')
        expect(result[:directors]).to include('Stanley Kubrick')
      end
    end
  end

  describe '#generate_quote_for_type' do
    let(:mock_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => {
                quote: 'Test quote',
                attribution: 'Test Movie'
              }.to_json
            }
          }
        ]
      }
    end

    before do
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(mock_response)
    end

    it 'generates a quote' do
      result = JSON.parse(service.generate_quote_for_type(movie_type, 'Test preferences'))
      expect(result['quote']).to eq('Test quote')
      expect(result['attribution']).to eq('Test Movie')
    end

    context 'when API call fails' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(StandardError)
      end

      it 'returns fallback quote' do
        result = JSON.parse(service.generate_quote_for_type(movie_type, 'Test preferences'))
        expect(result['quote']).to eq('Every story is unique, just like every viewer.')
        expect(result['attribution']).to eq('Movie Type')
      end
    end
  end

  describe '.all_personality_types' do
    context 'when force_refresh is false' do
      it 'uses cached values' do
        expect(Rails.cache).to receive(:fetch).with('openai_service/personality_types', expires_in: 1.day)
        OpenaiService.all_personality_types
      end
    end

    context 'when force_refresh is true' do
      it 'deletes cache and regenerates' do
        expect(Rails.cache).to receive(:delete).with('openai_service/personality_types')
        expect(Rails.cache).to receive(:fetch).with('openai_service/personality_types', expires_in: 1.day)
        OpenaiService.all_personality_types(force_refresh: true)
      end
    end

    it 'generates all possible personality types' do
      allow(Rails.cache).to receive(:fetch).and_yield
      allow_any_instance_of(OpenaiService).to receive(:generate_personality_description).and_return('Test description')
      
      types = OpenaiService.all_personality_types
      expect(types.keys.length).to eq(16) # 2^4 possible combinations
      expect(types['PWEX']).to include(:dimensions, :description)
    end
  end

  describe '#format_dimension_preferences' do
    let(:high_score_response) { create(:user_response, quiz_question: quiz_question, response_value: 5) }
    let(:low_score_response) { create(:user_response, quiz_question: quiz_question, response_value: 1) }
    let(:neutral_score_response) { create(:user_response, quiz_question: quiz_question, response_value: 3) }

    it 'formats high scores correctly' do
      result = service.send(:format_dimension_preferences, { personality_dimension => 5 })
      expect(result).to include('Strong preference for Plot')
    end

    it 'formats low scores correctly' do
      result = service.send(:format_dimension_preferences, { personality_dimension => 1 })
      expect(result).to include('Strong preference for Atmosphere')
    end

    it 'formats neutral scores correctly' do
      result = service.send(:format_dimension_preferences, { personality_dimension => 3 })
      expect(result).to include('Balanced between Plot and Atmosphere')
    end
  end
end
