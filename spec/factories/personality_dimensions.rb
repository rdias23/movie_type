FactoryBot.define do
  factory :personality_dimension do
    sequence(:name) { |n| "Dimension #{n}" }
    high_label { "High Option" }
    low_label { "Low Option" }
  end
end
