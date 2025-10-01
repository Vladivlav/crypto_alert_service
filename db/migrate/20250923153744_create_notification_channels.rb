class CreateNotificationChannels < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_channels do |t|
      t.string :channel_type
      t.jsonb :config
      t.boolean :is_active

      t.timestamps
    end
    add_index :notification_channels, :channel_type
  end
end
