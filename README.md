# MovieType 🎬

A cinematic personality profiler powered by AI that helps users discover their unique movie-watching style and get personalized film recommendations.

## About

MovieType creates a personalized, AI-enhanced film recommendation experience based on your "movie personality". Through a carefully crafted quiz, it determines your 4-letter movie personality type (similar to MBTI) and provides:

- AI-generated archetype title and poetic write-up about your cinematic tastes
- Curated film and director recommendations
- Insights into your movie-watching preferences

## Tech Stack

- Ruby on Rails 7
- Tailwind CSS
- ESBuild
- PostgreSQL
- OpenAI GPT API
- Turbo & Stimulus for enhanced interactivity

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   yarn install
   ```
3. Setup database:
   ```bash
   rails db:create db:migrate
   ```
4. Create a `.env` file with your OpenAI API key:
   ```
   OPENAI_API_KEY=your_key_here
   ```
5. Start the server:
   ```bash
   bin/dev
   ```

## Development

This project uses:
- Ruby 3.1.2
- Node.js
- PostgreSQL

Make sure you have these installed before setting up the project.
