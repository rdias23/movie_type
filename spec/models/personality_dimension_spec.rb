require 'rails_helper'

RSpec.describe PersonalityDimension, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:high_label) }
    it { should validate_presence_of(:low_label) }
  end

  describe 'associations' do
    it { should have_many(:quiz_questions) }
  end

  let(:dimension) { create(:personality_dimension,
    name: 'Narrative',
    high_label: 'Plot',
    low_label: 'Atmosphere'
  )}

  describe '#letter_for_score' do
    it 'returns high label letter for scores below 0.5' do
      expect(dimension.letter_for_score(0.0)).to eq('P')
      expect(dimension.letter_for_score(-1.0)).to eq('P')
      expect(dimension.letter_for_score(0.49)).to eq('P')
    end

    it 'returns low label letter for scores 0.5 and above' do
      expect(dimension.letter_for_score(0.5)).to eq('A')
      expect(dimension.letter_for_score(0.75)).to eq('A')
      expect(dimension.letter_for_score(1.0)).to eq('A')
    end

    it 'returns uppercase letters' do
      dimension = create(:personality_dimension,
        high_label: 'plot',
        low_label: 'atmosphere'
      )
      expect(dimension.letter_for_score(0.0)).to eq('P')
      expect(dimension.letter_for_score(1.0)).to eq('A')
    end
  end

  describe '.score_to_letter' do
    it 'returns high label letter for scores below 0.5' do
      expect(PersonalityDimension.score_to_letter(0.0, 'Plot', 'Atmosphere')).to eq('P')
      expect(PersonalityDimension.score_to_letter(-1.0, 'Plot', 'Atmosphere')).to eq('P')
      expect(PersonalityDimension.score_to_letter(0.49, 'Plot', 'Atmosphere')).to eq('P')
    end

    it 'returns low label letter for scores 0.5 and above' do
      expect(PersonalityDimension.score_to_letter(0.5, 'Plot', 'Atmosphere')).to eq('A')
      expect(PersonalityDimension.score_to_letter(0.75, 'Plot', 'Atmosphere')).to eq('A')
      expect(PersonalityDimension.score_to_letter(1.0, 'Plot', 'Atmosphere')).to eq('A')
    end

    it 'handles different label cases' do
      expect(PersonalityDimension.score_to_letter(0.0, 'plot', 'atmosphere')).to eq('P')
      expect(PersonalityDimension.score_to_letter(1.0, 'plot', 'atmosphere')).to eq('A')
    end
  end

  describe '#calculate_letter' do
    let(:quiz_question) { create(:quiz_question, personality_dimension: dimension) }
    
    context 'with single response' do
      let!(:response) { create(:user_response, quiz_question: quiz_question, response_value: 1) }
      
      it 'calculates correct letter for low score' do
        expect(dimension.calculate_letter([response])).to eq('P')
      end
    end

    context 'with multiple responses' do
      let!(:response1) { create(:user_response, quiz_question: quiz_question, response_value: 1) }
      let!(:response2) { create(:user_response, quiz_question: quiz_question, response_value: 2) }
      let!(:response3) { create(:user_response, quiz_question: quiz_question, response_value: 3) }
      
      it 'averages responses and calculates correct letter' do
        expect(dimension.calculate_letter([response1, response2, response3])).to eq('P')
      end
    end

    context 'with high scores' do
      let!(:response1) { create(:user_response, quiz_question: quiz_question, response_value: 4) }
      let!(:response2) { create(:user_response, quiz_question: quiz_question, response_value: 5) }
      
      it 'calculates correct letter for high scores' do
        expect(dimension.calculate_letter([response1, response2])).to eq('A')
      end
    end

    context 'with mixed scores' do
      let!(:response1) { create(:user_response, quiz_question: quiz_question, response_value: 1) }
      let!(:response2) { create(:user_response, quiz_question: quiz_question, response_value: 5) }
      
      it 'averages mixed scores correctly' do
        expect(dimension.calculate_letter([response1, response2])).to eq('P')
      end
    end
  end

  describe 'full dimension examples' do
    let(:narrative) { create(:personality_dimension,
      name: 'Narrative',
      high_label: 'Plot',
      low_label: 'Atmosphere'
    )}
    let(:tone) { create(:personality_dimension,
      name: 'Tone',
      high_label: 'Whimsy',
      low_label: 'Gravitas'
    )}
    let(:perspective) { create(:personality_dimension,
      name: 'Perspective',
      high_label: 'External',
      low_label: 'Internal'
    )}
    let(:interpretation) { create(:personality_dimension,
      name: 'Interpretation',
      high_label: 'Explicit',
      low_label: 'Ambiguous'
    )}

    it 'correctly maps all dimension types' do
      dimensions = [narrative, tone, perspective, interpretation]
      dimensions.each do |dim|
        expect(dim.letter_for_score(0.0)).to eq(dim.high_label[0].upcase)
        expect(dim.letter_for_score(1.0)).to eq(dim.low_label[0].upcase)
      end
    end
  end
end
