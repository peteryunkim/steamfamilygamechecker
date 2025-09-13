require 'discordrb'
require 'httparty'
require 'json'
require 'dotenv/load'
require_relative 'keep_alive'
require_relative 'cache_manager'

DISCORD_TOKEN = ENV['DISCORD_TOKEN']
STEAM_API_KEY = ENV['STEAM_API_KEY']
DISCORD_CHANNEL_ID = ENV['DISCORD_CHANNEL_ID'] 

if DISCORD_TOKEN.nil? || STEAM_API_KEY.nil? || DISCORD_CHANNEL_ID.nil?
  puts "❌ Missing environment variables! Did you set DISCORD_TOKEN, STEAM_API_KEY, and DISCORD_CHANNEL_ID in Render?"
  exit(1)
end

bot = Discordrb::Commands::CommandBot.new(
  token: DISCORD_TOKEN,
  prefix: "!"
)

# List of Steam users you want to track
STEAM_USERS = {
  "Petah Bread" => ENV['P'],
  "Timpotle"   => ENV['T'],
  "Orangee" => ENV['O'],
  "Nico"  => ENV['N'],
}

# Load cache at startup
CacheManager.load_cache

bot.ready do |_event|
  puts "✅ Logged in as #{bot.profile.username}"

  # Start background polling once bot is ready
  Thread.new do
    loop do
      begin
        channel = bot.channel(DISCORD_CHANNEL_ID.to_i)
        all_messages = []

        STEAM_USERS.each do |name, steam_id|
          new_games = fetch_games(steam_id)

          if new_games.empty?
            puts "⚠️ Could not fetch games for #{name} (#{steam_id})."
            next
          end

          added, removed = CacheManager.update_games(steam_id, new_games)

          unless added.empty? && removed.empty?
            user_msg = ["**#{name}**"]
            user_msg << "🎉 Bought: #{added.join(', ')}" unless added.empty?
            user_msg << "❌ Removed: #{removed.join(', ')}" unless removed.empty?
            all_messages << user_msg.join("\n")
          end
        end

        # Send one grouped message if there were updates
        unless all_messages.empty?
          final_msg = all_messages.join("\n\n")
          puts final_msg
          channel.send_message(final_msg) if channel
        end
      rescue => e
        puts "Error in polling loop: #{e}"
      end

      sleep 60 # wait 1 minute before checking again
    end
  end
end

# Command for testing
bot.command :ping do |event|
  event.respond "Pong!"
end

# Fetch owned Steam games
def fetch_games(steam_id)
  url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/"
  response = HTTParty.get(url, query: { key: STEAM_API_KEY, steamid: steam_id, include_appinfo: 1 })
  if response.code == 200 && response.parsed_response["response"]["games"]
    response.parsed_response["response"]["games"].map { |g| g["name"] }
  else
    []
  end
end

# Start keep-alive web server (for Render free tier)
KeepAlive.start

# Run bot
bot.run
