# frozen_string_literal: true

require 'json'

# Handles caching of user game data in a local JSON file.
# Provides methods to load, save, and update cached games for each user.
module CacheManager
  CACHE_FILE = 'games_cache.json'

  def self.load_cache
    if File.exist?(CACHE_FILE)
      JSON.parse(File.read(CACHE_FILE))
    else
      {}
    end
  end

  def self.save_cache(cache)
    File.write(CACHE_FILE, JSON.pretty_generate(cache))
  end

  def self.update_games(user_id, new_games)
    cache = load_cache
    old_games = cache[user_id] || []

    added = new_games - old_games
    removed = old_games - new_games

    cache[user_id] = new_games
    puts "Updated cache for user #{user_id}"
    puts "added: #{added}, removed: #{removed}"
    save_cache(cache)

    [added, removed]
  end
end
