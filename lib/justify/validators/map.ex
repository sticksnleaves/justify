defmodule Justify.Validators.Map do
  @moduledoc false

  def call(dataset, field, validator) do
    dataset = Justify.Dataset.new(dataset)
    value = Justify.Field.value(dataset, field, nil)

    case validate(value, validator) do
      [] ->
        dataset

      errors ->
        Justify.put_error(dataset, field, errors)
    end
  end

  defp validate(map, validator) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.reduce(map, fn key, dataset ->
      Justify.validate_embed(dataset, key, validator)
    end)
    |> Map.get(:errors)
  end

  defp validate(value, validator) do
    value
    |> validator.()
    |> Map.get(:errors, [])
  end
end
