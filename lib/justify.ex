defmodule Justify do
  @moduledoc """
  Justify is a data validation library for Elixir.

  The primary philosophy behind Justify is that it should be easy to validate
  data without schemas or types. All of Justify's validation functions will
  happily accept a plain ol' map.

  ```elixir
  iex> %{email: "madebyanthony"}
  ...> |> Justify.validate_required(:email)
  ...> |> Justify.validate_format(:email, ~r/\S+@\S+/)
  %Justify.Dataset{errors: [email: {"has invalid format", validation: :format}], valid?: false}
  ```

  Pretty simple. Not much more to it than that.

  ## Supported Validations

  * [`validate_acceptance/3`](https://hexdocs.pm/justify/Justify.html#validate_acceptance/3)
  * [`validate_confirmation/3`](https://hexdocs.pm/justify/Justify.html#validate_confirmation/3)
  * [`validate_embed/3`](https://hexdocs.pm/justify/Justify.html#validate_embed/3)
  * [`validate_exclusion/4`](https://hexdocs.pm/justify/Justify.html#validate_exclusion/4)
  * [`validate_format/4`](https://hexdocs.pm/justify/Justify.html#validate_format/4)
  * [`validate_inclusion/4`](https://hexdocs.pm/justify/Justify.html#validate_inclusion/4)
  * [`validate_length/3`](https://hexdocs.pm/justify/Justify.html#validate_length/3)
  * [`validate_required/3`](https://hexdocs.pm/justify/Justify.html#validate_required/3)
  """

  @doc """
  Validates the given field has a value of `true`.

  ## Options

  * `:message` - error message, defaults to "must be accepted"
  """
  @spec validate_acceptance(map, atom, Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_acceptance(dataset, field, opts \\ []),
    to: Justify.Validators.Acceptance,
    as: :call

  @doc """
  Validates the value of a given field matches it's confirmation field.

  By default, the field will be checked against a field with the same name
  but appended with `_confirmation`. It’s possible to provide a custom field by
  providing a value to the `:confirmation_field` option.

  Note that if the confirmation field is `nil` or missing, by default, an error
  will not be added. You can specify that the confirmation field is required in
  the options (see below).

  ## Options

  * `:confirmation_field` - name of the field to validate against
  * `:message` - error message, defaults to "does not match"
  * `:required?` - whether the confirmation field must contain a value
  """
  @spec validate_confirmation(map, atom, Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_confirmation(dataset, field, opts \\ []),
    to: Justify.Validators.Confirmation,
    as: :call

  @doc """
  Applies a validator function to a field containing an embedded value.

  An embedded value can be either a map or a list of maps.

  ## Example

      validator = fn(metadata) -> Justify.validate_required(metadata, :key) end

      data = %{metadata: [%{value: "a value"}]}

      validate_embed(data, :metadata, validator)
      #> %Justify.Dataset{errors: [metadata: [[key: {"can't be blank", validation: :required}]]], valid?: false}
  """
  @spec validate_embed(map, atom, fun) :: Justify.Dataset.t()
  defdelegate validate_embed(dataset, field, validator),
    to: Justify.Validators.Embed,
    as: :call

  @doc """
  Validates the value for the given field is not contained within the provided
  enumerable.

  ## Options

  * `:message` - error message, defaults to "is reserved"
  """
  @spec validate_exclusion(map, atom, Enum.t(), Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_exclusion(dataset, field, enum, opts \\ []),
    to: Justify.Validators.Exclusion,
    as: :call

  @doc """
  Validates the value of the given field matches the provided format.

  ## Options

  * `:message` - error message, defaults to "has invalid format"
  """
  @spec validate_format(map, Regex.t(), Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_format(dataset, format),
    to: Justify.Validators.Format,
    as: :call

  @spec validate_format(map, atom, Regex.t(), Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_format(dataset, field, format, opts \\ []),
    to: Justify.Validators.Format,
    as: :call

  @doc """
  Validates the value for the given field is contained within the provided
  enumerable.

  ## Options

  * `:message` - error message, defaults to "is invalid"
  """
  @spec validate_inclusion(map, atom, Enum.t(), Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_inclusion(dataset, field, enum, opts \\ []),
    to: Justify.Validators.Inclusion,
    as: :call

  @doc """
  Validates the length of a string or list.

  ## Options

  * `:count` - how to calculate the length of a string. Must be one of
               `:codepoints`, `:graphemes` or `:bytes`. Defaults to
               `:graphemes`.
  * `:is` - the exact length match
  * `:min` - match a length greater than or equal to
  * `:max` - match a length less than or equal to
  * `:message` - error message, defaults to one of the following variants:
    * for strings
      * “should be %{count} character(s)”
      * “should be at least %{count} character(s)”
      * “should be at most %{count} character(s)”
    * for binary
      * “should be %{count} byte(s)”
      * “should be at least %{count} byte(s)”
      * “should be at most %{count} byte(s)”
    * for lists
      * “should have %{count} item(s)”
      * “should have at least %{count} item(s)”
      * “should have at most %{count} item(s)”
  """
  @spec validate_length(map, Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_length(dataset, opts),
    to: Justify.Validators.Length,
    as: :call

  @spec validate_length(map, atom, Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_length(dataset, field, opts),
    to: Justify.Validators.Length,
    as: :call

  @doc """
  Validates that one or more fields has a value.

  ## Options

  * `:message` - error message, defaults to "must be accepted"
  * `:trim?` - remove whitespace before validating, defaults to `true`
  """
  @spec validate_required(map, atom | [atom], Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_required(dataset, fields, opts \\ []),
    to: Justify.Validators.Required,
    as: :call

  @spec validate_map(map, atom, Keyword.t()) :: Justify.Dataset.t()
  defdelegate validate_map(dataset, fields, opts \\ []),
    to: Justify.Validators.Map,
    as: :call

  @doc """
  Adds an error to the dataset.

  An optional keyword list can be used to provide additional contextual
  information about the error.
  """
  @spec add_error(Justify.Dataset.t(), atom, String.t(), Keyword.t()) :: Justify.Dataset.t()
  def add_error(dataset, field, message, keys \\ []) do
    put_error(dataset, field, {message, keys})
  end

  @doc false
  def put_error(dataset, field, error) do
    errors =
      dataset
      |> Map.get(:errors)
      |> Enum.concat([{field, error}])

    %{dataset | errors: errors, valid?: false}
  end
end
