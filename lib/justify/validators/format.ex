defmodule Justify.Validators.Format do
  @moduledoc false

  @default_message "has invalid format"

  def call(dataset, format), do: call(dataset, dataset, format)
  def call(dataset, format, opts) when is_list(opts), do: call(dataset, dataset, format, opts)

  def call(dataset, field, format, opts \\ []) do
    dataset = Justify.Dataset.new(dataset)

    value = Justify.Field.value(dataset, field, "")

    message = Keyword.get(opts, :message, @default_message)

    if value =~ format do
      dataset
    else
      Justify.add_error(dataset, field, message, validation: :format)
    end
  end
end
