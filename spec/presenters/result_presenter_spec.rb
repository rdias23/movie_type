require 'rails_helper'

RSpec.describe ResultPresenter do
  let(:user_email) { 'test@example.com' }
  
  # Create all four personality dimensions
  let!(:narrative_dimension) { create(:personality_dimension, 
    name: 'Narrative',
    high_label: 'Plot',
    low_label: 'Atmosphere'
  )}
  let!(:tone_dimension) { create(:personality_dimension,
    name: 'Tone',
    high_label: 'Whimsy',
    low_label: 'Gravitas'
  )}
  let!(:perspective_dimension) { create(:personality_dimension,
    name: 'Perspective',
    high_label: 'External',
    low_label: 'Internal'
  )}
  let!(:interpretation_dimension) { create(:personality_dimension,
    name: 'Interpretation',
    high_label: 'Explicit',
    low_label: 'Ambiguous'
  )}
  
  # Create questions for each dimension
  let!(:narrative_question) { create(:quiz_question, 
    personality_dimension: narrative_dimension,
    prompt: 'Narrative question?',
    high_text: 'Plot focused',
    low_text: 'Atmosphere focused'
  )}
  let!(:tone_question) { create(:quiz_question,
    personality_dimension: tone_dimension,
    prompt: 'Tone question?',
    high_text: 'Whimsical',
    low_text: 'Serious'
  )}
  let!(:perspective_question) { create(:quiz_question,
    personality_dimension: perspective_dimension,
    prompt: 'Perspective question?',
    high_text: 'External',
    low_text: 'Internal'
  )}
  let!(:interpretation_question) { create(:quiz_question,
    personality_dimension: interpretation_dimension,
    prompt: 'Interpretation question?',
    high_text: 'Explicit',
    low_text: 'Ambiguous'
  )}
  
  # Create responses for all dimensions
  let!(:narrative_response) { create(:user_response, 
    user_email: user_email,
    quiz_question: narrative_question,
    response_value: 4
  )}
  let!(:tone_response) { create(:user_response,
    user_email: user_email,
    quiz_question: tone_question,
    response_value: 2
  )}
  let!(:perspective_response) { create(:user_response,
    user_email: user_email,
    quiz_question: perspective_question,
    response_value: 5
  )}
  let!(:interpretation_response) { create(:user_response,
    user_email: user_email,
    quiz_question: interpretation_question,
    response_value: 1
  )}

  before do
    allow_any_instance_of(OpenaiService).to receive(:generate_personality_description)
      .and_return("Test personality description")
    allow_any_instance_of(OpenaiService).to receive(:generate_recommendations)
      .and_return({
        films: ["Test Film"],
        directors: ["Test Director"]
      })
    allow_any_instance_of(OpenaiService).to receive(:generate_quote_for_type)
      .and_return({ quote: "Test quote", attribution: "Test attribution" }.to_json)
      
    # Mock letter_for_score to return predictable results
    allow_any_instance_of(PersonalityDimension).to receive(:letter_for_score) do |dimension, score|
      score > 0 ? dimension.high_label[0] : dimension.low_label[0]
    end
  end

  describe '#initialize' do
    it 'creates a new presenter with an email' do
      presenter = ResultPresenter.new(user_email)
      expect(presenter.user_email).to eq(user_email)
    end

    it 'calculates results on initialization' do
      presenter = ResultPresenter.new(user_email)
      expect(presenter.movie_type).not_to be_nil
      expect(presenter.personality_description).not_to be_nil
      expect(presenter.recommendations).not_to be_nil
    end
  end

  describe '#calculate_results' do
    it 'handles OpenAI failures gracefully' do
      allow_any_instance_of(OpenaiService).to receive(:generate_personality_description)
        .and_raise(StandardError)
      
      presenter = ResultPresenter.new(user_email)
      expect(presenter.personality_description).to eq(presenter.send(:generate_fallback_description))
      expect(presenter.recommendations).to eq(presenter.send(:generate_fallback_recommendations))
    end
  end

  describe '#calculate_movie_type' do
    it 'generates the correct movie type from responses' do
      presenter = ResultPresenter.new(user_email)
      expect(presenter.movie_type).to be_a(String)
      expect(presenter.movie_type.length).to eq(4) # Should be 4-letter code
    end

    it 'handles missing responses gracefully' do
      new_email = 'no_responses@example.com'
      presenter = ResultPresenter.new(new_email)
      expect(presenter.movie_type).to be_a(String)
      expect(presenter.movie_type.length).to eq(4)
    end
  end

  describe '#dimension_breakdowns' do
    it 'returns formatted dimension information' do
      presenter = ResultPresenter.new(user_email)
      breakdowns = presenter.dimension_breakdowns
      
      expect(breakdowns).to be_an(Array)
      expect(breakdowns.first).to include(
        :name,
        :letter,
        :high_label,
        :low_label,
        :leans_high
      )
    end
  end

  describe '#calculate_dimension_score' do
    it 'calculates the correct normalized score' do
      presenter = ResultPresenter.new(user_email)
      score = presenter.send(:calculate_dimension_score, narrative_dimension)
      expect(score).to be_between(-1.0, 1.0)
    end

    it 'returns 0 for dimensions without responses' do
      new_dimension = create(:personality_dimension, name: 'Empty')
      presenter = ResultPresenter.new(user_email)
      score = presenter.send(:calculate_dimension_score, new_dimension)
      expect(score).to eq(0)
    end
  end
end
