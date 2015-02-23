require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AggregatorTest < Test::Unit::TestCase
  include TestHelpers::StorageKeys
  include TestHelpers::Fixtures

  def setup
    @storage = Storage.instance(true)
    @storage.flushdb
    Memoizer.reset!
    seed_data
  end

  test 'aggregate_all increments_all_stats_counters' do
    Aggregator.aggregate_all([default_transaction])

    assert_equal '1', @storage.get(service_key(1001, 3001, :eternity))
    assert_equal '1', @storage.get(service_key(1001, 3001, :month,  '20100501'))
    assert_equal '1', @storage.get(service_key(1001, 3001, :week,   '20100503'))
    assert_equal '1', @storage.get(service_key(1001, 3001, :day,    '20100507'))
    assert_equal '1', @storage.get(service_key(1001, 3001, :hour,   '2010050713'))

    assert_equal '1', @storage.get(application_key(1001, 2001, 3001, :eternity))
    assert_equal '1', @storage.get(application_key(1001, 2001, 3001, :year,   '20100101'))
    assert_equal '1', @storage.get(application_key(1001, 2001, 3001, :month,  '20100501'))
    assert_equal '1', @storage.get(application_key(1001, 2001, 3001, :week,   '20100503'))
    assert_equal '1', @storage.get(application_key(1001, 2001, 3001, :day,    '20100507'))
    assert_equal '1', @storage.get(application_key(1001, 2001, 3001, :hour,   '2010050713'))
    assert_equal '1', @storage.get(application_key(1001, 2001, 3001, :minute, '201005071323'))
  end

  test 'aggregate_all updates application set' do
    Aggregator.aggregate_all([default_transaction])

    assert_equal ['2001'], @storage.smembers("stats/{service:1001}/cinstances")
  end

  test 'aggregate_all does not update service set' do
    assert_no_change :of => lambda { @storage.smembers('stats/services') } do
      Aggregator.aggregate_all([default_transaction])
    end
  end

  test 'aggregate_all sets expiration time for volatile keys' do
    Aggregator.aggregate_all([default_transaction])

    key = application_key('1001', '2001', '3001', :minute, 201005071323)
    ttl = @storage.ttl(key)

    assert_not_equal(-1, ttl)
    assert ttl >  0
    assert ttl <= 180
  end

  test 'aggregate takes into account setting the counter value' do
    v = Array.new(10, default_transaction)
    v << transaction_with_set_value
    v << default_transaction

    Aggregator.aggregate_all(v)

    assert_equal '666', @storage.get(application_key(1001, 2001, 3001, :hour, '2010050713'))
  end
end
