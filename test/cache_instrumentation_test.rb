require "helper"

class CacheInstrumentationTest < ActiveSupport::TestCase
  attr_reader :cache

  setup :setup_subscriber, :setup_cache
  teardown :teardown_subscriber, :teardown_cache

  def setup_subscriber
    @subscriber = Railsd::Subscribers::ActiveSupport.subscribe(adapter)
  end

  def teardown_subscriber
    ActiveSupport::Notifications.unsubscribe @subscriber if @subscriber
  end

  def setup_cache
    ActiveSupport::Cache::MemoryStore.instrument = true
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  def teardown_cache
    ActiveSupport::Cache::MemoryStore.instrument = nil
    @cache = nil
  end

  test "cache_read miss" do
    cache.read('foo')

    assert_timer "active_support.cache_read"
    assert_counter "active_support.cache_miss"
  end

  test "cache_read hit" do
    cache.write('foo', 'bar')
    adapter.clear
    cache.read('foo')

    assert_timer "active_support.cache_read"
    assert_counter "active_support.cache_hit"
  end

  test "cache_generate" do
    cache.fetch('foo') { |key| :generate_me_please }
    assert_timer "active_support.cache_generate"
  end

  test "cache_fetch with hit" do
    cache.write('foo', 'bar')
    adapter.clear
    cache.fetch('foo') { |key| :never_gets_here }

    assert_timer "active_support.cache_fetch"
    assert_timer "active_support.cache_fetch_hit"
  end

  test "cache_fetch with miss" do
    cache.fetch('foo') { 'foo value set here' }

    assert_timer "active_support.cache_fetch"
    assert_timer "active_support.cache_generate"
    assert_timer "active_support.cache_write"
  end

  test "cache_write" do
    cache.write('foo', 'bar')
    assert_timer "active_support.cache_write"
  end

  test "cache_delete" do
    cache.delete('foo')
    assert_timer "active_support.cache_delete"
  end

  test "cache_exist?" do
    cache.exist?('foo')
    assert_timer "active_support.cache_exist"
  end
end
