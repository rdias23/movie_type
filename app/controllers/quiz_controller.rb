class QuizController < ApplicationController
  def start
    # Clear old responses when starting a new quiz
    if params[:clear_responses]
      UserResponse.where(user_email: session[:user_email]).delete_all if session[:user_email]
      session[:user_email] = nil
      session[:responses] = nil
    end
    session[:responses] = nil
  end

  def question
    @current_question = QuizQuestion.find(params[:id])
    @total_questions = QuizQuestion.count
    
    # Calculate the current question number (1-based) by ordering all questions
    @current_question_number = QuizQuestion.where("id <= ?", @current_question.id).count
    @progress = ((@current_question_number / @total_questions.to_f) * 100).round

    # Initialize or preserve the session
    if params[:email].present?
      session[:user_email] = params[:email]
      session[:responses] = []
      # Clear old responses for this email
      UserResponse.where(user_email: params[:email]).delete_all
    elsif !session[:user_email] && request.referrer&.include?('quiz/question')
      # If user hit back and session was lost, redirect to start
      redirect_to quiz_start_path, alert: "Please start the quiz again"
      return
    end

    # Ensure we have an email before proceeding
    unless session[:user_email]
      redirect_to quiz_start_path, alert: "Please enter your email to start the quiz"
      return
    end
  end

  def answer
    # Ensure we have an email
    unless session[:user_email]
      redirect_to quiz_start_path, alert: "Please enter your email to start the quiz"
      return
    end

    Rails.logger.info "Answer params: #{params.inspect}"
    Rails.logger.info "Session: #{session.inspect}"

    # Save the response
    response = UserResponse.create!(
      user_email: session[:user_email],
      quiz_question_id: params[:question_id],
      response_value: params[:value]
    )

    Rails.logger.info "Created response: #{response.inspect}"

    # Store in session for backup
    session[:responses] ||= []
    session[:responses] << {
      question_id: params[:question_id],
      value: params[:value]
    }

    next_question = QuizQuestion.where("id > ?", params[:question_id]).first
    Rails.logger.info "Next question: #{next_question.inspect}"

    if next_question
      redirect_to quiz_question_path(next_question)
    else
      redirect_to quiz_result_path
    end
  rescue StandardError => e
    Rails.logger.error "Error in answer action: #{e.message}\n#{e.backtrace.join("\n")}"
    flash[:error] = "Something went wrong. Please try again."
    redirect_to root_path
  end

  def result
    unless session[:user_email]
      redirect_to quiz_start_path, alert: "Please enter your email to start the quiz"
      return
    end

    @presenter = ResultPresenter.new(session[:user_email])
  rescue StandardError => e
    Rails.logger.error("Error generating results: #{e.message}\n#{e.backtrace.join("\n")}")
    flash[:error] = "We encountered an error generating your results. Please try again."
    redirect_to root_path
  end
end
