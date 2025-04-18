# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts "Clearing existing data..."
UserResponse.destroy_all
QuizQuestion.destroy_all
PersonalityDimension.destroy_all

# Create personality dimensions
puts "Creating personality dimensions..."
dimensions = {
  narrative: PersonalityDimension.create!(
    name: "Narrative Preference",
    high_label: "Plot",
    low_label: "Atmosphere",
    description: "Measures preference between plot-driven narratives and atmospheric experiences"
  ),
  
  tone: PersonalityDimension.create!(
    name: "Tonal Inclination",
    high_label: "Whimsy",
    low_label: "Gravitas",
    description: "Distinguishes between preference for lighter, whimsical works versus serious, weighty films"
  ),
  
  perspective: PersonalityDimension.create!(
    name: "Viewing Perspective",
    high_label: "External",
    low_label: "Internal",
    description: "Captures preference for objective, observational storytelling versus subjective, character-focused narratives"
  ),
  
  complexity: PersonalityDimension.create!(
    name: "Interpretive Depth",
    high_label: "Explicit",
    low_label: "Ambiguous",
    description: "Measures appreciation for straightforward versus layered, ambiguous meanings"
  )
}

# Create quiz questions
puts "Creating quiz questions..."

# Narrative Questions (Plot vs Atmosphere)
[
  {
    prompt: "When watching a film, what matters more to you?",
    high_text: "A well-structured story with clear progression",
    low_text: "The mood, visuals, and overall feeling"
  },
  {
    prompt: "Which would you rather watch?",
    high_text: "A tightly-plotted thriller that keeps you guessing",
    low_text: "A dreamy film that washes over you like a wave"
  },
  {
    prompt: "What do you value more in cinema?",
    high_text: "Clever plot twists and satisfying resolutions",
    low_text: "Beautiful imagery and emotional resonance"
  }
].each do |q|
  dimensions[:narrative].quiz_questions.create!(q)
end

# Tone Questions (Whimsy vs Gravitas)
[
  {
    prompt: "Which type of film speaks to you more?",
    high_text: "A playful comedy that delights in life's absurdities",
    low_text: "A serious drama that explores life's complexities"
  },
  {
    prompt: "What's your preferred emotional experience?",
    high_text: "Being entertained and uplifted",
    low_text: "Being moved and challenged"
  },
  {
    prompt: "Which director's approach resonates more?",
    high_text: "Wes Anderson's quirky, stylized worlds",
    low_text: "Ingmar Bergman's philosophical explorations"
  }
].each do |q|
  dimensions[:tone].quiz_questions.create!(q)
end

# Perspective Questions (External vs Internal)
[
  {
    prompt: "How do you prefer to experience a story?",
    high_text: "Observing events unfold from the outside",
    low_text: "Deep diving into characters' inner worlds"
  },
  {
    prompt: "Which approach interests you more?",
    high_text: "Seeing how events affect multiple characters",
    low_text: "Following one character's intimate journey"
  },
  {
    prompt: "What's more important to you?",
    high_text: "Understanding what happened",
    low_text: "Understanding how it felt"
  }
].each do |q|
  dimensions[:perspective].quiz_questions.create!(q)
end

# Complexity Questions (Explicit vs Ambiguous)
[
  {
    prompt: "How do you like stories to end?",
    high_text: "With clear resolution and answers",
    low_text: "With room for interpretation"
  },
  {
    prompt: "What's more satisfying?",
    high_text: "Understanding exactly what the film means",
    low_text: "Finding your own meaning in the film"
  },
  {
    prompt: "Which viewing experience do you prefer?",
    high_text: "Following a clear, direct narrative",
    low_text: "Piecing together subtle meanings and symbols"
  }
].each do |q|
  dimensions[:complexity].quiz_questions.create!(q)
end

puts "Seed data created successfully!"
puts "Created #{PersonalityDimension.count} dimensions and #{QuizQuestion.count} questions"
