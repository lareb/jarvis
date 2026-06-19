class CreateCommands < ActiveRecord::Migration[7.2]
  def change
    create_table :commands do |t|
      t.references :user, null: false, foreign_key: true
      t.text :raw_text, null: false
      t.string :intent
      t.string :status, null: false, default: "pending"
      t.jsonb :response, null: false, default: {}
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :commands, [:user_id, :status]
    add_index :commands, :intent
  end
end
