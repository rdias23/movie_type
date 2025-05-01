FactoryBot.define do
  factory :quiz_question do
    association :personality_dimension
    sequence(:prompt) { |n| "Test Question #{n}?" }
    high_text { "High Option Description" }
    low_text { "Low Option Description" }
  end
end
