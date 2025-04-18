class CreateQuizQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_questions do |t|
      t.text :prompt
      t.references :personality_dimension, null: false, foreign_key: true
      t.string :high_text
      t.string :low_text

      t.timestamps
    end
  end
end
