require 'fluent/test'
require 'fluent/plugin/out_format'

class FormatOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf)
    Fluent::Test::OutputTestDriver.new(Fluent::FormatOutput).configure(conf)
  end

  def test_format
    d1 = create_driver %[
      type format
      tag formatted
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %{key2}
    ]

    d1.run do
      d1.emit({'key1' => 'val1', 'key2' => 'val2'})
      d1.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'key2' => 'val2',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> val2'
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d1.records

    d2 = create_driver %[
      type format
      tag formatted
      include_original_fields true
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %{key2}
    ]

    d2.run do
      d2.emit({'key1' => 'val1', 'key2' => 'val2'})
      d2.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'key2' => 'val2',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> val2'
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d2.records

    d3 = create_driver %[
      type format
      tag formatted
      include_original_fields false
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %{key2}
    ]

    d3.run do
      d3.emit({'key1' => 'val1', 'key2' => 'val2'})
      d3.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> val2'
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d3.records

    # Time format with bad parameter
    d4 = create_driver %[
      type format
      tag formatted
      include_original_fields false
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %t{key2}
    ]

    d4.run do
      d4.emit({'key1' => 'val1', 'key2' => "Not a time"})
      d4.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d4.records

    # Time format with timestamp int parameter
    d5 = create_driver %[
      type format
      tag formatted
      include_original_fields false
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %t{key2}
    ]

    d5.run do
      d5.emit({'key1' => 'val1', 'key2' => 1424347199})
      d5.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> 19/Feb/2015:12:59:59 +0100'
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d5.records

    # Time format with timestamp string parameter
    d6 = create_driver %[
      type format
      tag formatted
      include_original_fields false
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %t{key2}
    ]

    d6.run do
      d6.emit({'key1' => 'val1', 'key2' => "1424347199"})
      d6.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> 19/Feb/2015:12:59:59 +0100'
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d6.records

    # Time format with proper parameter and custom format
    d7 = create_driver %[
      type format
      tag formatted
      include_original_fields false
      time_format %d/%b/%Y
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %t{key2}
    ]

    d7.run do
      d7.emit({'key1' => 'val1', 'key2' => 1424347199})
      d7.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> 19/Feb/2015'
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d7.records

    # Time format with proper parameter and BAD custom format
    d8 = create_driver %[
      type format
      tag formatted
      include_original_fields false
      time_format %O%X%O
      key1 %{key1} changed!
      new_key1 key1 -> %{key1}
      new_key2 key1 -> %{key1}, key2 -> %t{key2}
    ]

    d8.run do
      d8.emit({'key1' => 'val1', 'key2' => 1424347199})
      d8.emit({'key1' => 'val1'})
    end

    assert_equal [
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        # Bad format parts are ignored
        'new_key2' => 'key1 -> val1, key2 -> %O12:59:59%O'
      },
      {
        'key1' => 'val1 changed!',
        'new_key1' => 'key1 -> val1',
        'new_key2' => 'key1 -> val1, key2 -> '
      }
    ], d8.records
  end
end
