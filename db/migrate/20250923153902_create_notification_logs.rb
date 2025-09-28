class CreateNotificationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_logs do |t|
      t.string :channel_type
      t.jsonb :message
      t.string :status

      t.timestamps
    end
  end
end
