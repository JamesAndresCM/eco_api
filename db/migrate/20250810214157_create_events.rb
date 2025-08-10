class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :aggregate_type
      t.bigint :aggregate_id
      t.string :event_type
      t.jsonb :payload
      t.datetime :published
      t.timestamps
    end
  end
end
