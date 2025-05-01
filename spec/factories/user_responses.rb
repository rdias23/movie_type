FactoryBot.define do
  factory :user_response do
    sequence(:user_email) { |n| "user#{n}@example.com" }
    association :quiz_question
    response_value { rand(1..5) }
  end
end
