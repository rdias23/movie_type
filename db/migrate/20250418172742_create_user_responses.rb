class CreateUserResponses < ActiveRecord::Migration[7.2]
  def change
    create_table :user_responses do |t|
      t.string :user_email
      t.references :quiz_question, null: false, foreign_key: true
      t.integer :response_value

      t.timestamps
    end
  end
end
