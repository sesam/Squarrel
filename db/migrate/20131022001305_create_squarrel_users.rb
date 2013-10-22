class CreateSquarrelUsers < ActiveRecord::Migration
  def change
    create_table :squarrel_users do |t|
      t.string :pub_key, null: false

      t.timestamps
    end

    add_index :squarrel_users, :pub_key, unique: true
  end
end
