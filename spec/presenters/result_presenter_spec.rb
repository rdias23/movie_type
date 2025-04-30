require 'rails_helper'

RSpec.describe ResultPresenter do
  describe '#initialize' do
    it 'creates a new presenter with an email' do
      presenter = ResultPresenter.new('test@example.com')
      expect(presenter.user_email).to eq('test@example.com')
    end
  end
end
