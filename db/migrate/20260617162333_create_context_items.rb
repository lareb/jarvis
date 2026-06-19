class CreateContextItems < ActiveRecord::Migration[7.2]
  def change
    create_table :context_items do |t|
      t.references :command, null: false, foreign_key: true
      t.string :source, null: false
      t.string :external_id
      t.string :title, null: false
      t.text :body
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at

      t.timestamps
    end

    add_index :context_items, [:command_id, :source]
    add_index :context_items, :occurred_at
  end
end
