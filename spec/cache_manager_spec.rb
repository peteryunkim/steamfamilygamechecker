# frozen_string_literal: true

require_relative '../cache_manager'

RSpec.describe CacheManager do
  let(:test_cache_file) { 'test_games_cache.json' }
  let(:user_id) { 'user123' }
  let(:initial_games) { ['Game A', 'Game B'] }
  let(:new_games) { ['Game B', 'Game C'] }

  before do
    stub_const('CacheManager::CACHE_FILE', test_cache_file)
    File.write(test_cache_file, '{}')
  end

  after do
    File.delete(test_cache_file) if File.exist?(test_cache_file)
  end

  describe '.load_cache' do
    it 'returns an empty hash if cache file does not exist' do
      File.delete(test_cache_file)
      expect(CacheManager.load_cache).to eq({})
    end

    it 'returns parsed JSON if cache file exists' do
      File.write(test_cache_file, '{"user123": ["Game A"]}')
      expect(CacheManager.load_cache).to eq({ 'user123' => ['Game A'] })
    end
  end

  describe '.save_cache' do
    it 'writes the cache to the file' do
      cache = { user_id => initial_games }
      CacheManager.save_cache(cache)
      expect(JSON.parse(File.read(test_cache_file))).to eq({ user_id => initial_games })
    end
  end

  describe '.update_games' do
    it 'returns added and removed games' do
      CacheManager.save_cache({ user_id => initial_games })
      added, removed = CacheManager.update_games(user_id, new_games)
      expect(added).to eq(['Game C'])
      expect(removed).to eq(['Game A'])
    end

    it 'updates the cache file' do
      CacheManager.update_games(user_id, new_games)
      expect(CacheManager.load_cache[user_id]).to eq(new_games)
    end

    it 'returns only the new game when a user with multiple games adds one' do
      games_before = ['Game X', 'Game Y', 'Game Z']
      games_after = ['Game X', 'Game Y', 'Game Z', 'Game W']
      CacheManager.save_cache({ user_id => games_before })
      added, removed = CacheManager.update_games(user_id, games_after)
      expect(added).to eq(['Game W'])
      expect(removed).to eq([])
    end
  end
end
