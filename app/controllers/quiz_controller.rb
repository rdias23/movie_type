class QuizController < ApplicationController
  def start
    # Show the quiz introduction
  end

  def question
    @current_question = QuizQuestion.find(params[:id])
    @total_questions = QuizQuestion.count
    @progress = ((params[:id].to_i / @total_questions.to_f) * 100).round

    # If this is the first question, initialize the session
    if params[:id].to_i == QuizQuestion.first.id
      session[:user_email] = params[:email]
      session[:responses] = []
    end
  end

  def answer
    # Save the response
    UserResponse.create!(
      user_email: session[:user_email],
      quiz_question_id: params[:question_id],
      response_value: params[:value]
    )

    # Store in session for backup
    session[:responses] << {
      question_id: params[:question_id],
      value: params[:value]
    }

    next_question = QuizQuestion.where("id > ?", params[:question_id]).first

    if next_question
      redirect_to quiz_question_path(next_question)
    else
      redirect_to quiz_result_path
    end
  end

  def result
    @user_email = session[:user_email]
    @movie_type = UserResponse.calculate_type(@user_email)
    
    # Get AI-generated content
    openai = OpenaiService.new
    @personality_description = openai.generate_personality_description(@movie_type)
    @recommendations = openai.generate_recommendations(@movie_type, UserResponse.where(user_email: @user_email))
    
    # Clear session after getting results
    session[:responses] = nil
  rescue StandardError => e
    Rails.logger.error("Error generating results: #{e.message}")
    flash[:error] = "We encountered an error generating your results. Please try again."
    redirect_to root_path
  end
end
