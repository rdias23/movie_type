class QuizMailer < ApplicationMailer
  def results_email(user_email, data)
    @movie_type = data[:movie_type]
    @personality_description = data[:personality_description]
    @recommendations = data[:recommendations]
    @quote = data[:quote]
    @quote_attribution = data[:quote_attribution]
    @dimension_breakdowns = data[:dimension_breakdowns]
    
    mail(
      to: user_email,
      subject: "Your Movie Type Results: #{@movie_type}"
    )
  end
end
