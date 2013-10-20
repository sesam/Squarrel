class CreateSquarrelAuthentications < ActiveRecord::Migration
  def change
    create_table :squarrel_authentications do |t|
      t.string :nut, null: false
      t.string :orig_ip, null: false
      t.string :ip, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_index :squarrel_authentications, :nut, unique: true
  end
end
