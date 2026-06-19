class CreateAiSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_summaries do |t|
      t.references :command, null: false, foreign_key: true, index: { unique: true }
      t.text :summary
      t.jsonb :action_items, null: false, default: []
      t.text :suggested_response
      t.decimal :confidence_score, precision: 5, scale: 2, null: false, default: 0

      t.timestamps
    end

  end
end
