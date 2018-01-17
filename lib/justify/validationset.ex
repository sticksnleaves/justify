defmodule Justify.Validationset do
  @moduledoc """
  """

  defstruct [ data: nil, errors: [], valid?: true ]

  @type error :: { String.t(), Keyword.t() }

  @type t :: %__MODULE__{
    data: map,
    errors: [{ atom, error }],
    valid?: boolean
  }

  @doc """
  Adds an error to the validationset.

  An additional keyword list can be passed to provide additional contextual
  information for the error.
  """
  @spec add_error(t, atom, String.t, Keyword.t) :: t
  def add_error(%__MODULE__{ errors: errors } = validationset, field, message, keys \\ []) do
    %{ validationset | errors: [{ field, { message, keys } } | errors], valid?: false }
  end

  @doc """
  Validates the given field is `true`.

  ## Options
  * `:message` - the message on failure, defaults to "must be accepted"
  """
  @spec validate_acceptance(t | map | struct, atom, Keyword.t) :: t
  def validate_acceptance(data, field, opts \\ [])
  def validate_acceptance(%__MODULE__{ data: data } = validationset, field, opts) do
    value   = data[field]
    message = opts[:message] || "must be accepted"

    if (value != true) do
      add_error(validationset, field, message, validation: :acceptance)
    else
      validationset
    end
  end
  def validate_acceptance(data, field, opts) when is_map(data),
    do: validate_acceptance(%__MODULE__{ data: data }, field, opts)

  @doc """
  Validates that the given field matches the confirmation value for that
  field.

  By default, the field will be checked against a field with the same name
  appended with `_confirmation` (e.g. `:email` would be checked against
  `:email_confirmation`). It's possible to provide a custom field by providing
  a value to the `:confirmation_field` option.

  Note that if the confirmation field is `nil` or missing, by default an error
  will not be added. You can specify that the confirmation field is required in
  the options (see below). Note, the confirmation field does not need to be
  added to structs.

  ## Options

  * `:confirmation_field` - the field to check against
  * `:message` - the message on failure, defaults to "does not match"
  * `:required` - sets whether existence of a confirmation field is
                  required
  """
  @spec validate_confirmation(t | map | struct, atom, Keyword.t) :: t
  def validate_confirmation(data, field, opts \\ [])
  def validate_confirmation(%__MODULE__{ data: data } = validationset, field, opts) do
    confirmation_field = opts[:confirmation_field] || get_confirmation_field(field)
    message            = opts[:message] || "does not match"

    value              = data[field]
    confirmation_value = data[confirmation_field]

    if (!field_is_confirmed(value, confirmation_value, opts[:required] || false)) do
      add_error(validationset, field, message, validation: :confirmation)
    else
      validationset
    end
  end
  def validate_confirmation(data, field, opts) when is_map(data),
    do: validate_confirmation(%__MODULE__{ data: data }, field, opts)

  defp field_is_confirmed(_value, nil, false),
    do: true
  defp field_is_confirmed(value, confirmation_value, _required),
    do: value == confirmation_value


  defp get_confirmation_field(field),
    do:  String.to_atom("#{Atom.to_string(field)}_confirmation")

  @doc """
  Validates a field's value is not included in the given enumerable.

  ## Options

  * `:message` - the message on failure, defaults to "is reserved"
  """
  @spec validate_exclusion(t | map | struct, atom, Enum.t, Keyword.t) :: t
  def validate_exclusion(data, field, enum, opts \\ [])
  def validate_exclusion(%__MODULE__{ data: data } = validationset, field, enum, opts) do
    message = opts[:message] || "is reserved"
    value   = data[field]

    if value in enum do
      add_error(validationset, field, message, validation: :exclusion)
    else
      validationset
    end
  end
  def validate_exclusion(data, field, enum, opts) when is_map(data),
    do: validate_exclusion(%__MODULE__{ data: data }, field, enum, opts)

  @doc """
  Validates that a field's value is of the given format.

  The format must be expressed as a regular expression.

  ## Options

  * `:message` - the message on failure, defaults to "has invalid format"
  """
  @spec validate_format(t | map | struct, atom, Regex.t, Keyword.t) :: t
  def validate_format(data, field, format, opts \\ [])
  def validate_format(%__MODULE__{ data: data } = validationset, field, format, opts) do
    message = opts[:message] || "has invalid format"
    value   = data[field]

    if !is_binary(value) || !(value =~ format) do
      add_error(validationset, field, message, validation: :format)
    else
      validationset
    end
  end
  def validate_format(data, field, format, opts) when is_map(data),
    do: validate_format(%__MODULE__{ data: data }, field, format, opts)

  @doc """
  Validates a field's value is included in the given enumerable.

  ## Options

  * `:message` - the message on failure, defaults to "is invalid"
  """
  @spec validate_inclusion(t | map | struct, atom, Enum.t, Keyword.t) :: t
  def validate_inclusion(data, field, enum, opts \\ [])
  def validate_inclusion(%__MODULE__{ data: data } = validationset, field, enum, opts) do
    message = opts[:message] || "is invalid"
    value   = data[field]

    if !(value in enum) do
      add_error(validationset, field, message, validation: :inclusion)
    else
      validationset
    end
  end
  def validate_inclusion(data, field, enum, opts) when is_map(data),
    do: validate_inclusion(%__MODULE__{ data: data }, field, enum, opts)

  @doc """
  Validates a field's value is a string or list of the given length.

  ## Options

  * `:is` - the length must be exactly this value
  * `:min` - the length must be greater than or equal to this value
  * `:max` - the length must be less than or equal to this value
  * `:count` - what length to count for string, `:graphemes` (default) or
               `:codepoints`
  * `:message` - the message on failure, depending on the value type, is one of
    * for strings
      * “should be %{count} character(s)”
      * “should be at least %{count} character(s)”
      * “should be at most %{count} character(s)”
    * for lists
      * “should have %{count} item(s)”
      * “should have at least %{count} item(s)”
      * “should have at most %{count} item(s)”
  """
  @spec validate_length(t | map | struct, atom, Keyword.t) :: t
  def validate_length(%__MODULE__{ data: data } = validationset, field, opts) do
    count = opts[:count] || :graphemes
    value = data[field]

    { value_type, length } =
      case count do
        :codepoints when is_binary(value) ->
          { :string, length(String.codepoints(value)) }
        :graphemes when is_binary(value) ->
          { :string, length(String.graphemes(value)) }
        _ when is_list(value) ->
          { :list, length(value) }
      end

    validationset
    |> check_is_length(field, value_type, length, opts)
    |> check_max_length(field, value_type, length, opts)
    |> check_min_length(field, value_type, length, opts)
  end
  def validate_length(data, field, opts) when is_map(data),
    do: validate_length(%__MODULE__{ data: data }, field, opts)

  defp check_is_length(validationset, field, value_type, length, opts) do
    message = get_length_message(value_type, :is, opts[:message])
    is      = opts[:is]

    if (is && is != length) do
      add_error(validationset, field, message, count: is, kind: :is, validation: :length)
    else
      validationset
    end
  end

  defp check_max_length(validationset, field, value_type, length, opts) do
    message = get_length_message(value_type, :max, opts[:message])
    max     = opts[:max]

    if (max && max < length) do
      add_error(validationset, field, message, count: max, kind: :max, validation: :length)
    else
      validationset
    end
  end

  defp check_min_length(validationset, field, value_type, length, opts) do
    message = get_length_message(value_type, :min, opts[:message])
    min     = opts[:min]

    if (min && min > length) do
      add_error(validationset, field, message, count: min, kind: :min, validation: :length)
    else
      validationset
    end
  end

  defp get_length_message(:string, :is, supplied_message),
    do: supplied_message || "should be %{count} character(s)"
  defp get_length_message(:list, :is, supplied_message),
    do: supplied_message || "should have %{count} item(s)"

  defp get_length_message(:string, :max, supplied_message),
    do: supplied_message || "should be at most %{count} character(s)"
  defp get_length_message(:list, :max, supplied_message),
    do: supplied_message || "should have at most %{count} item(s)"

  defp get_length_message(:string, :min, supplied_message),
    do: supplied_message || "should be at least %{count} character(s)"
  defp get_length_message(:list, :min, supplied_message),
    do: supplied_message || "should have at least %{count} item(s)"

  @doc """
  Validates that one or more fields are present in the validationset.

  If the value of a field is `nil` or a string made only of whitespace, the
  validationset is marked as invalid.

  If a field does not exist within the validationset, the validationset is
  marked as invalid.

  ## Options

  * `:message` - the message on failure, defaults to "can't be blank"
  """
  @spec validate_required(t | map | struct, list | atom, Keyword.t) :: t
  def validate_required(data, fields, opts \\ [])
  def validate_required(%__MODULE__{} = validationset, fields, opts) do
    fields  = List.wrap(fields)
    message = opts[:message] || "can't be blank"

    validate_field_is_required(validationset, fields, message)
  end
  def validate_required(data, fields, opts) when is_map(data),
    do: validate_required(%__MODULE__{ data: data }, fields, opts)


  defp validate_field_is_required(%__MODULE__{ data: data } = validationset, [field | t], message) do
    value = data[field]

    validationset =
      if (is_nil(value) || String.trim(value) == "") do
        add_error(validationset, field, message, validation: :required)
      else
        validationset
      end

    validate_field_is_required(validationset, t, message)
  end
  defp validate_field_is_required(validationset, _fields, _message) do
    validationset
  end
end
