class CreatePriceThresholds < ActiveRecord::Migration[8.0]
  def change
    create_table :price_thresholds do |t|
      t.string :symbol, null: false
      t.decimal :value, precision: 20, scale: 10, null: false
      t.string :operator, null: false
      t.boolean :is_active, null: false

      t.timestamps
    end
  end
end
