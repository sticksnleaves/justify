defmodule Justify.Validators.Required do
  @moduledoc false

  @default_message "can't be blank"

  def call(dataset, fields, opts \\ []) do
    dataset = Justify.Dataset.new(dataset)

    fields = List.wrap(fields)

    message = Keyword.get(opts, :message, @default_message)

    Enum.reduce(fields, dataset, fn
      (field, acc) ->
        dataset.data
        |> Map.get(field)
        |> maybe_trim_value(Keyword.get(opts, :trim?, true))
        |> case do
             value when value in [nil, ""] ->
               Justify.add_error(acc, field, message, validation: :required)
              _otherwise ->
                dataset
           end
    end)
  end

  #
  # private
  #

  defp maybe_trim_value(nil, _does_not_matter), do: nil
  defp maybe_trim_value(value, true) when is_binary(value), do: String.trim(value)
  defp maybe_trim_value(value, _do_not_trim), do: value
end
