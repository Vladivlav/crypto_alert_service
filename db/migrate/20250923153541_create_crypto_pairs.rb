class CreateCryptoPairs < ActiveRecord::Migration[8.0]
  def change
    create_table :crypto_pairs do |t|
      t.string :symbol

      t.timestamps
    end
    add_index :crypto_pairs, :symbol, unique: true
  end
end
