require 'rails_helper'

RSpec.describe UserResponse, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:user_email) }
    it { should validate_presence_of(:response_value) }
    it { should validate_inclusion_of(:response_value).in_range(1..5) }

    context 'email format' do
      it 'accepts valid email addresses' do
        valid_emails = [
          'user@example.com',
          'user.name@example.co.uk',
          'user+tag@example.com',
          'user123@sub.example.com',
          'USER@EXAMPLE.COM'
        ]

        valid_emails.each do |email|
          user_response = build(:user_response, user_email: email)
          expect(user_response).to be_valid
        end
      end

      it 'rejects invalid email addresses' do
        invalid_emails = [
          'invalid',
          'user@',
          '@example.com',
          'user@.com',
          'user@example.',
          'user name@example.com',
          'user@exam ple.com',
          'user@example..com'
        ]

        invalid_emails.each do |email|
          user_response = build(:user_response, user_email: email)
          expect(user_response).not_to be_valid
          expect(user_response.errors[:user_email]).to be_present
        end
      end
    end

    context 'response_value validation' do
      it 'accepts values between 1 and 5' do
        (1..5).each do |value|
          user_response = build(:user_response, response_value: value)
          expect(user_response).to be_valid
        end
      end

      it 'rejects values outside 1-5 range' do
        [-1, 0, 6, 10].each do |value|
          user_response = build(:user_response, response_value: value)
          expect(user_response).not_to be_valid
          expect(user_response.errors[:response_value]).to include('is not included in the list')
        end
      end

      it 'rejects non-numeric values' do
        ['three', nil].each do |value|
          user_response = build(:user_response, response_value: value)
          expect(user_response).not_to be_valid
        end
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:quiz_question) }

    it 'cascades properly with quiz_question' do
      response = create(:user_response)
      expect { response.quiz_question.destroy }.to change(UserResponse, :count).by(-1)
    end
  end

  describe '#normalized_score' do
    let(:quiz_question) { create(:quiz_question) }
    subject { create(:user_response, quiz_question: quiz_question) }

    it 'delegates to quiz_question for normalization' do
      expect(quiz_question).to receive(:normalize_response).with(subject.response_value)
      subject.normalized_score
    end

    it 'returns the normalized score' do
      allow(quiz_question).to receive(:normalize_response).and_return(-0.5)
      expect(subject.normalized_score).to eq(-0.5)
    end

    it 'handles different response values' do
      [1, 2, 3, 4, 5].each do |value|
        response = create(:user_response, quiz_question: quiz_question, response_value: value)
        allow(quiz_question).to receive(:normalize_response).with(value).and_return((value - 3) / 2.0)
        expect(response.normalized_score).to eq((value - 3) / 2.0)
      end
    end
  end

  describe '.calculate_type' do
    let(:dimension1) { create(:personality_dimension, high_label: 'Plot', low_label: 'Atmosphere') }
    let(:dimension2) { create(:personality_dimension, high_label: 'Whimsy', low_label: 'Gravitas') }
    let(:question1) { create(:quiz_question, personality_dimension: dimension1) }
    let(:question2) { create(:quiz_question, personality_dimension: dimension2) }
    let(:email) { 'test@example.com' }

    context 'with valid responses' do
      before do
        create(:user_response, quiz_question: question1, user_email: email, response_value: 1) # Strong Plot
        create(:user_response, quiz_question: question2, user_email: email, response_value: 5) # Strong Gravitas
      end

      it 'calculates the correct type' do
        expect(UserResponse.calculate_type(email)).to eq('PG')
      end

      it 'handles responses in different orders' do
        new_email = 'test2@example.com'
        create(:user_response, quiz_question: question2, user_email: new_email, response_value: 5)
        create(:user_response, quiz_question: question1, user_email: new_email, response_value: 1)
        expect(UserResponse.calculate_type(new_email)).to eq('PG')
      end
    end

    context 'with multiple responses per dimension' do
      before do
        # Two Plot responses (avg = strong Plot)
        create(:user_response, quiz_question: question1, user_email: email, response_value: 1)
        create(:user_response, quiz_question: question1, user_email: email, response_value: 2)
        # Two Gravitas responses (avg = moderate Gravitas)
        create(:user_response, quiz_question: question2, user_email: email, response_value: 4)
        create(:user_response, quiz_question: question2, user_email: email, response_value: 4)
      end

      it 'averages responses for each dimension' do
        expect(UserResponse.calculate_type(email)).to eq('PG')
      end

      it 'handles responses created at different times' do
        travel_to(1.day.from_now) do
          create(:user_response, quiz_question: question1, user_email: email, response_value: 1)
        end
        travel_back
        expect(UserResponse.calculate_type(email)).to eq('PG')
      end
    end

    context 'with missing email' do
      it 'returns nil for nil email' do
        expect(UserResponse.calculate_type(nil)).to be_nil
      end

      it 'returns nil for empty email' do
        expect(UserResponse.calculate_type('')).to be_nil
      end

      it 'returns nil for whitespace email' do
        expect(UserResponse.calculate_type('   ')).to be_nil
      end
    end

    context 'with no responses' do
      it 'returns an empty string for nonexistent email' do
        expect(UserResponse.calculate_type('nonexistent@example.com')).to eq('')
      end

      it 'returns an empty string when all responses are for other emails' do
        create(:user_response, quiz_question: question1, user_email: 'other@example.com')
        expect(UserResponse.calculate_type(email)).to eq('')
      end
    end

    context 'with neutral responses' do
      it 'defaults to high_label for neutral scores' do
        create(:user_response, quiz_question: question1, user_email: email, response_value: 3)
        create(:user_response, quiz_question: question2, user_email: email, response_value: 3)
        expect(UserResponse.calculate_type(email)).to eq('PW')
      end
    end
  end

  describe '.debug_responses_for_email' do
    let(:quiz_question) { create(:quiz_question) }
    let(:email) { 'test@example.com' }
    let!(:response) { create(:user_response, 
      quiz_question: quiz_question,
      user_email: email,
      response_value: 3,
      created_at: Time.current
    )}

    it 'logs debug information' do
      expect(Rails.logger).to receive(:info).with("DEBUGGING: Viewing responses for #{email}")
      UserResponse.debug_responses_for_email(email)
    end

    it 'returns response details in expected format' do
      result = UserResponse.debug_responses_for_email(email).first
      expect(result).to include(
        email: email,
        question_id: quiz_question.id,
        value: 3
      )
      expect(result[:created_at]).to be_present
    end

    it 'returns empty array for non-existent email' do
      expect(UserResponse.debug_responses_for_email('nonexistent@example.com')).to be_empty
    end

    it 'includes all responses for an email' do
      create(:user_response, quiz_question: quiz_question, user_email: email)
      expect(UserResponse.debug_responses_for_email(email).length).to eq(2)
    end

    context 'orders by creation time' do
      let!(:older_response) do
        travel_to(1.day.ago) do
          create(:user_response, quiz_question: quiz_question, user_email: email)
        end
      end

      let!(:newer_response) do
        travel_to(1.hour.ago) do
          create(:user_response, quiz_question: quiz_question, user_email: email)
        end
      end

      it 'orders responses by creation time' do
        results = UserResponse.debug_responses_for_email(email)
        expect(results.map { |r| r[:created_at] }).to eq([older_response.created_at, newer_response.created_at, response.created_at])
      end
    end

    it 'handles responses from multiple questions' do
      question2 = create(:quiz_question)
      create(:user_response, quiz_question: question2, user_email: email)
      results = UserResponse.debug_responses_for_email(email)
      question_ids = results.map { |r| r[:question_id] }
      expect(question_ids).to contain_exactly(quiz_question.id, question2.id)
    end
  end
end
