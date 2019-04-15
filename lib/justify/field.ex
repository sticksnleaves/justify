defmodule Justify.Field do
  def value(dataset, field, default \\ "")

  def value(dataset, field, default) when is_map(dataset) do
    case dataset.data do
      m when is_map(m) -> Map.get(m, field)
      l when is_list(l) -> Enum.at(l, field)
      x -> x
    end || default
  end
end
