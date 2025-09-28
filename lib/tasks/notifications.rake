require "json"

namespace :notifications do
  desc "Parses command line arguments into channel type and config hash."
  task :create_channel, [ :channel_type, :config_key_val_pairs ] => :environment do |_, args|
    channel_type  = args[:channel_type].to_s
    config_params = JSON.parse(args[:config_key_val_pairs])

    begin
      factory_config  = NotificationChannels::Builders::ChannelCreation.for(channel_type)
      contract        = factory_config[:contract].new
      scenario        = factory_config[:scenario].new

      form_result = contract.call(config_params)

      if form_result.success?
        result = scenario.call(**form_result.to_h)

        if result.success?
          puts "Channel created successfully"
        else
          puts result.failure
        end
      else
        puts "Channel was failed to create. Reason: #{form_result.errors.to_h}"
      end
    rescue NotificationChannels::Errors::InvalidChannelType => e
      puts "Can not create a channel. Reason: #{e}"
    end
  end
end
