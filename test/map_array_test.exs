defmodule MapArrayTest do
  use ExUnit.Case
  doctest MapArray
  require MapArray

  setup do
    array = MapArray.new([:zero, :one, :two])
    nums = nums = MapArray.new(1..20)
    {:ok, array: array, nums: nums}
  end

  describe "is_index/1 guard" do
    test "true for pos ints" do
      Enum.each(1..200, fn i ->
        assert MapArray.is_index(i) == true
      end)
    end

    test "true for 0" do
      assert MapArray.is_index(0) == true
    end

    test "false for neg ints" do
      Enum.each(-1..-200, fn i ->
        assert MapArray.is_index(i) == false
      end)
    end

    test "false for everthing else" do
      non_indexes = [
        'true',
        "false",
        nil,
        true,
        false,
        :other,
        1.1,
        %{},
        [],
        ""
      ]

      Enum.each(non_indexes, fn item -> MapArray.is_index(item) == false end)
    end

    test "can be used as a guard" do
      case Enum.random([1, 2]) do
        x when MapArray.is_index(x) -> assert true
      end
    end
  end

  describe "new/1" do
    test "turns an enumerable into a map of index => item" do
      assert MapArray.new([:a, :b, :c, :d]) == %{
               0 => :a,
               1 => :b,
               2 => :c,
               3 => :d
             }
    end
  end

  describe "append/2" do
    test "adds an item to the end of the collection", %{array: array} do
      assert MapArray.len(array) == 3
      array = MapArray.append(array, :last)
      assert MapArray.len(array) == 4

      assert array == %{
               0 => :zero,
               1 => :one,
               2 => :two,
               3 => :last
             }
    end
  end

  describe "prepend/2" do
    test "adds an item to the 0th index of the collection and pushes everything else back by 1",
         %{array: array} do
      assert MapArray.len(array) == 3
      array = MapArray.prepend(array, :first)
      assert MapArray.len(array) == 4

      assert array == %{
               0 => :first,
               1 => :zero,
               2 => :one,
               3 => :two
             }
    end
  end

  describe "seek_index_up/2" do
    test "returns {:ok, i} for the first match iterating from the beginning", %{array: array} do
      assert {:ok, 1} == MapArray.seek_index_up(array, fn item -> item == :one end)
    end

    test "returns :error for no match", %{array: array} do
      assert :error == MapArray.seek_index_up(array, fn item -> item == :not_in_array end)
    end
  end

  describe "seek_index_up/3" do
    test "returns {:ok, i} for the first match iterating up from the given index", %{nums: nums} do
      # first even is index 1
      is_even? = fn item -> rem(item, 2) == 0 end
      assert {:ok, 1} == MapArray.seek_index_up(nums, is_even?)
      # first even starting at index 4 is index 5
      assert {:ok, 5} == MapArray.seek_index_up(nums, 4, is_even?)
      # first even starting at index 5 is index 5
      assert {:ok, 5} == MapArray.seek_index_up(nums, 5, is_even?)
    end

    test "returns :error for no match from the given index", %{nums: nums} do
      assert :error == MapArray.seek_index_up(nums, 4, &is_atom/1)
    end
  end

  describe "seek_up/2" do
    test "returns {:ok, value} for the first match iterating up from the beginning", %{
      array: array
    } do
      is_even? = fn item -> item in [:zero, :two, :four] end
      # first found is zero
      assert {:ok, :zero} == MapArray.seek_up(array, is_even?)
    end

    test "returns :error for no match", %{array: array} do
      assert :error == MapArray.seek_up(array, 1, &is_float/1)
    end
  end

  describe "seek_up/3" do
    test "returns {:ok, value} for the first match iterating up from the given index", %{
      array: array
    } do
      is_even? = fn item -> item in [:zero, :two, :four] end
      assert {:ok, :two} == MapArray.seek_up(array, 1, is_even?)
    end

    test "returns :error for no match", %{array: array} do
      is_even? = fn item -> item in [:zero, :two, :four] end
      assert :error == MapArray.seek_up(array, 3, is_even?)
    end
  end

  describe "seek_index_down/2" do
    test "returns {:ok, i} for the first match iterating from the end", %{array: array} do
      assert MapArray.len(array) == 3
      assert {:ok, 2} == MapArray.seek_index_down(array, fn _ -> true end)
    end

    test "returns :error for no match", %{array: array} do
      assert :error == MapArray.seek_index_down(array, fn _ -> false end)
    end
  end

  describe "seek_index_down/3" do
    test "returns {:ok, i} for the first match iterating down from the given index", %{
      array: array
    } do
      zero_or_two = fn name -> name in [:zero, :two] end
      assert {:ok, 0} == MapArray.seek_index_down(array, 1, zero_or_two)
    end

    test "returns :error for no match", %{array: array} do
      assert :error == MapArray.seek_index_down(array, 1, fn _ -> false end)
    end

    test "returns :error for out of range start", %{array: array} do
      assert MapArray.len(array) == 3
      assert :error == MapArray.seek_index_down(array, 22, fn _ -> true end)
    end
  end

  describe "seek_down/2" do
    test "returns {:ok, value} for the first match iterating down from the end", %{
      array: array
    } do
      zero_or_two = fn name -> name in [:zero, :two] end
      assert {:ok, :two} == MapArray.seek_down(array, zero_or_two)
    end

    test "returns :error for no match", %{array: array} do
      assert :error == MapArray.seek_down(array, fn _ -> false end)
    end
  end

  describe "seek_down/3" do
    test "returns {:ok, value} for the first match iterating down from the given index", %{
      array: array
    } do
      zero_or_two = fn name -> name in [:zero, :two] end
      assert {:ok, :zero} == MapArray.seek_down(array, 1, zero_or_two)
    end

    test "returns :error for no match", %{array: array} do
      assert :error == MapArray.seek_index_down(array, 1, fn _ -> false end)
    end
  end

  describe "len/1" do
    test "returns the size (number of items)" do
      array = MapArray.new(1..10)
      assert MapArray.len(array) == 10
    end
  end

  describe "slice/2" do
    test "slices an array" do
      array = MapArray.new([2, 4, 6, 8, 10])
      assert MapArray.slice(array, 0..1) == [2, 4]
    end

    test "slices safely for out-of-range" do
      array = MapArray.new([2, 4, 6, 8, 10])
      assert MapArray.slice(array, 10..11) == []
    end
  end

  describe "map/2 with mapper/1" do
    test "maps through an array from beginning to end" do
      array = MapArray.new([2, 4, 6, 8, 10])

      assert MapArray.map(array, fn n -> n * n end) == [
               4,
               16,
               36,
               64,
               100
             ]
    end
  end

  describe "map/2 with mapper/2" do
    test "maps through an array from beginning to end" do
      array = MapArray.new([2, 4, 6, 8, 10])

      assert MapArray.map(array, fn n, i -> i * n end) == [
               0,
               4,
               12,
               24,
               40
             ]
    end
  end

  describe "reverse_map/2 with mapper/2" do
    test "maps through an array from beginning to end" do
      array = MapArray.new([2, 4, 6, 8, 10])

      assert MapArray.reverse_map(array, fn n, i -> i * n end) == [
               40,
               24,
               12,
               4,
               0
             ]
    end
  end

  describe "reverse_map/2 with mapper/1" do
    test "maps through an array from end to beginning" do
      array = MapArray.new([2, 4, 6, 8, 10])

      assert MapArray.reverse_map(array, fn n -> n * n end) == [
               100,
               64,
               36,
               16,
               4
             ]
    end
  end

  describe "to_list/1" do
    test "turns an array into a list of the same order" do
      items = Enum.into(1..5, [])
      array = MapArray.new(items)
      result = MapArray.to_list(array)
      assert result == items
    end
  end

  describe "to_reversed_list/1" do
    test "turns an array into a list of the reversed order" do
      items = Enum.into(1..5, [])
      array = MapArray.new(items)
      result = MapArray.to_reversed_list(array)
      assert result == Enum.reverse(items)
    end
  end

  describe "reduce/3 with reducer/2" do
    test "has the same result as Enum.reduce/3" do
      reducer = fn item, acc ->
        [item * item | acc]
      end

      array = MapArray.new(1..5)
      assert MapArray.reduce(array, [], reducer) == [25, 16, 9, 4, 1]
    end
  end

  describe "reduce/3 with reducer/3" do
    test "includes the item, acc, and index" do
      reducer = fn item, acc, i ->
        [item * item + i | acc]
      end

      array = MapArray.new(1..5)
      assert MapArray.reduce(array, [], reducer) == [29, 19, 11, 5, 1]
    end
  end

  describe "reverse_reduce/3 with reducer/2" do
    test "has the same result as Enum.reduce/3" do
      reducer = fn item, acc ->
        [item * item | acc]
      end

      array = MapArray.new(1..5)
      assert MapArray.reverse_reduce(array, [], reducer) == [1, 4, 9, 16, 25]
    end
  end

  describe "reverse_reduce/3 with reducer/3" do
    test "includes the item, acc, and index" do
      reducer = fn item, acc, i ->
        [item * item + i | acc]
      end

      array = MapArray.new(1..5)
      assert MapArray.reverse_reduce(array, [], reducer) == [1, 5, 11, 19, 29]
    end
  end
end
