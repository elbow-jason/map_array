defmodule MapArray do
  @moduledoc """
  Documentation for MapArray.
  """

  defguard is_index(i) when is_integer(i) and i >= 0

  @type index :: non_neg_integer()
  @type t :: %{non_neg_integer() => any()}

  @spec append(t(), any) :: t()
  def append(map, item) do
    Map.put(map, map_size(map), item)
  end

  @doc """
  This is an expensive operation as it forces reconstruction of the entire map.
  """
  @spec prepend(t(), any) :: t()
  def prepend(map, item) do
    map
    |> Map.new(fn {i, v} -> {i + 1, v} end)
    |> Map.put(0, item)
  end

  @spec new(Enumerable.t()) :: t()
  def new(enumerable) do
    Enum.reduce(enumerable, %{}, fn item, acc ->
      append(acc, item)
    end)
  end

  @spec seek_index_up(map(), nil | non_neg_integer, (any -> boolean())) ::
          {:ok, index()} | :error
  def seek_index_up(map, start \\ 0, finder) when is_index(start) do
    start
    |> iter_up()
    |> fetch_index(map, finder)
  end

  @spec seek_index_down(map(), nil | non_neg_integer, (any -> boolean())) ::
          {:ok, index()} | :error
  def seek_index_down(map, start \\ nil, finder) when is_index(start) or is_nil(start) do
    start = start || len(map) - 1

    start
    |> iter_down()
    |> fetch_index(map, finder)
  end

  @spec seek_down(map(), nil | non_neg_integer(), (any -> boolean())) :: {:ok, any} | :error
  def seek_down(map, start \\ nil, finder) do
    case seek_index_down(map, start, finder) do
      {:ok, i} ->
        Map.fetch(map, i)

      :error ->
        :error
    end
  end

  @spec seek_up(map(), non_neg_integer(), (any -> boolean())) :: {:ok, any} | :error
  def seek_up(map, start \\ 0, finder) do
    case seek_index_up(map, start, finder) do
      {:ok, i} ->
        Map.fetch(map, i)

      :error ->
        :error
    end
  end

  @spec len(map) :: non_neg_integer()
  def len(map), do: map_size(map)

  @spec map(map, (any -> any)) :: [any]
  def map(map, mapper) when is_map(map) and is_function(mapper, 1) do
    0
    |> iter_up()
    |> Stream.map(fn i ->
      map
      |> Map.fetch!(i)
      |> mapper.()
    end)
    |> Enum.take(map_size(map))
  end

  @spec slice(any, Range.t()) :: [any]
  def slice(map, a..b) do
    a..b
    |> Stream.map(fn i -> Map.fetch(map, i) end)
    |> Stream.filter(fn item -> match?({:ok, _}, item) end)
    |> Stream.map(fn {:ok, value} -> value end)
    |> Enum.into([])
  end

  @spec reverse_map(map, (any -> any)) :: [any]
  def reverse_map(map, mapper) when is_map(map) and is_function(mapper, 1) do
    n = map_size(map) - 1

    n
    |> iter_down()
    |> Stream.map(fn i ->
      map
      |> Map.fetch!(i)
      |> mapper.()
    end)
    |> Enum.take(map_size(map))
  end

  @spec to_list(map) :: [any]
  def to_list(map) when is_map(map) do
    map(map, fn x -> x end)
  end

  @spec to_reversed_list(map) :: [any]
  def to_reversed_list(map) do
    reverse_map(map, fn x -> x end)
  end

  defp iter_up(start) when is_index(start) do
    Stream.iterate(start, fn i -> i + 1 end)
  end

  defp iter_down(start) when is_integer(start) and start >= 0 do
    Stream.iterate(start, fn i -> i - 1 end)
  end

  defp fetch_index(iter, map, matcher) do
    iter
    |> Enum.reduce_while(nil, fn i, _ ->
      do_get_index(map, i, matcher)
    end)
    |> case do
      nil -> :error
      i when is_index(i) -> {:ok, i}
    end
  end

  defp do_get_index(map, i, matcher) do
    with(
      {:ok, item} <- Map.fetch(map, i),
      {:match?, true} <- {:match?, matcher.(item)}
    ) do
      {:halt, i}
    else
      :error ->
        {:halt, nil}

      {:match?, false} ->
        {:cont, nil}
    end
  end
end
