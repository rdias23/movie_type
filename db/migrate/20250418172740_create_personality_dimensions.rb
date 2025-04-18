class CreatePersonalityDimensions < ActiveRecord::Migration[7.2]
  def change
    create_table :personality_dimensions do |t|
      t.string :name
      t.string :high_label
      t.string :low_label
      t.text :description

      t.timestamps
    end
  end
end
