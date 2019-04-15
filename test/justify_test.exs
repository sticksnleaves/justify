defmodule JustifyTest do
  use ExUnit.Case, async: true

  describe "add_error/4" do
    test "adds an error to the dataset" do
      field = :field
      message = "message"
      keys = [key: "value"]

      dataset = Justify.add_error(%Justify.Dataset{}, field, message, keys)

      assert %Justify.Dataset{ errors: [{ ^field, { ^message, ^keys } }], valid?: false } = dataset
    end
  end

  describe "validate_acceptance/3" do
    test "adds an error if value is not `true`" do
      field = :field

      data = Map.new([{ field, false }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "must be accepted", validation: :acceptance } }],
               valid?: false
             } = Justify.validate_acceptance(data, field)
    end

    test "does not add an error if value is `true`" do
      field = :field

      data = Map.new([{ field, true }])

      assert %Justify.Dataset{
                data: ^data,
                errors: [],
                valid?: true
              } = Justify.validate_acceptance(data, field)
    end

    test "does not add an error if value is `nil`" do
      field = :field

      data = Map.new([{ field, nil }])

      assert %Justify.Dataset{
                data: ^data,
                errors: [],
                valid?: true
              } = Justify.validate_acceptance(data, field)
    end

    test "uses a custom error message when provided" do
      field = :field
      message = "message"

      data = Map.new([{ field, false }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { ^message, validation: :acceptance } }],
               valid?: false
             } = Justify.validate_acceptance(data, field, message: message)
    end
  end

  describe "validate_confirmation/3" do
    test "adds an error if the confirmation value does not match the provided value" do
      field = :field

      confirmation_field = :field_confirmation

      data = Map.new([{ field, "value" }, { confirmation_field, "confirmation_value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "does not match", validation: :confirmation } }],
               valid?: false
             } = Justify.validate_confirmation(data, field)
    end

    test "adds an error if the confirmation value is `nil` and `:required?` is `true`" do
      field = :field

      confirmation_field = :field_confirmation

      data = Map.new([{ field, "value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^confirmation_field, { "can't be blank", validation: :required } }],
               valid?: false
             } = Justify.validate_confirmation(data, field, required?: true)
    end

    test "does not add an error if the confirmation value matches" do
      field = :field

      confirmation_field = :field_confirmation

      value = "value"

      data = Map.new([{ field, value }, { confirmation_field, value }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_confirmation(data, field)
    end

    test "uses a different confirmation field when `:confirmation_field` is set" do
      field = :field

      confirmation_field = :another_confirmation_field

      data = Map.new([{ field, "value" }, { confirmation_field, "confirmation value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "does not match", validation: :confirmation } }],
               valid?: false
             } = Justify.validate_confirmation(data, field, confirmation_field: confirmation_field)
    end

    test "uses a custom error message when provided" do
      field = :field
      message = "message"

      confirmation_field = :field_confirmation

      data = Map.new([{ field, "value" }, { confirmation_field, "confirmation_value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { ^message, validation: :confirmation } }],
               valid?: false
             } = Justify.validate_confirmation(data, field, message: message)
    end
  end

  describe "validate_embed/3" do
    test "adds an error if an embedded map is invalid" do
      field = :field

      embed_field = :embed_field
      message = "message"
      keys = [validation: :custom]

      data = Map.new([{ field, Map.new([{ embed_field, false }]) }])

      fun = fn(_value) -> Justify.add_error(%Justify.Dataset{}, embed_field, message, keys) end

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, [{ ^embed_field, { ^message, ^keys } }] }],
               valid?: false
             } = Justify.validate_embed(data, field, fun)
    end

    test "adds an error if an embedded list is invalid" do
      field = :field

      embed_field = :embed_field
      message = "message"
      keys = [validation: :custom]

      embed_data = Map.new([{ embed_field, false }])

      data = Map.new([{ field, [embed_data, embed_data] }])

      fun = fn(_value) -> Justify.add_error(%Justify.Dataset{}, embed_field, message, keys) end

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, [[{ ^embed_field, { ^message, ^keys } }], [{ ^embed_field, { ^message, ^keys } }]] }],
               valid?: false
             } = Justify.validate_embed(data, field, fun)
    end

    test "does not add an error if the embedded value is valid" do
      field = :field

      embed_field = :embed_field

      embed_data = Map.new([{ embed_field, true }])

      data = Map.new([{ field, embed_data }])

      fun = fn(value) -> value end

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_embed(data, field, fun)
    end

    test "does not add an error if value is `nil`" do
      field = :field

      embed_field = :embed_field
      message = "message"
      keys = [validation: :custom]

      data = Map.new([{ field, nil }])

      fun = fn(_value) -> Justify.add_error(%Justify.Dataset{}, embed_field, message, keys) end

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_embed(data, field, fun)
    end

    test "can validate embedded lists" do
      data = %{key: ["123", "1"]}

      assert %Justify.Dataset{
               errors: [
                 key: [
                   [
                     {"1", _}
                   ]
                 ]
               ],
               valid?: false
             } =
               Justify.validate_embed(data, :key, fn d ->
                 Justify.validate_length(d, min: 2)
               end)
    end
  end

  describe "validate_exclusion/4" do
    test "adds an error if value is contained within enum" do
      field = :field

      value = "value"

      data = Map.new([{ field, value }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "is reserved", validation: :exclusion } }],
               valid?: false
             } = Justify.validate_exclusion(data, field, [value])
    end

    test "does not add an error if the value is not contained within enum" do
      field = :field

      data = Map.new([{ field, "value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_exclusion(data, field, ["another value"])
    end

    test "uses a custom error message when provided" do
      field = :field

      value = "value"

      message = "message"

      data = Map.new([{ field, value }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { ^message, validation: :exclusion } }],
               valid?: false
             } = Justify.validate_exclusion(data, field, [value], message: message)
    end

    test "does not add an error if value is `nil`" do
      field = :field

      data = Map.new([{ field, nil }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_exclusion(data, field, ["a value"])
    end
  end

  describe "validate_format/4" do
    test "adds an error if value does not match the provided format" do
      field = :field

      data = Map.new([{ field, "value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "has invalid format", validation: :format } }],
               valid?: false
             } = Justify.validate_format(data, field, ~r/\d/)
    end

    test "does not add an error if value does match the provided format" do
      field = :field

      value = "value"

      data = Map.new([{ field, value }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_format(data, field, ~r/#{value}/)
    end

    test "uses a custom error message when provided" do
      field = :field

      message = "message"

      data = Map.new([{ field, "value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { ^message, validation: :format } }],
               valid?: false
             } = Justify.validate_format(data, field, ~r/\d/, message: message)
    end

    test "can validate a simple value" do
      data = "message"

      assert %Justify.Dataset{
               data: ^data,
               errors: [{^data, {_, validation: :format}}],
               valid?: false
             } = Justify.validate_format(data, ~r/\d/)
    end
  end

  describe "validate_inclusion/4" do
    test "adds an error if value is not contained within enum" do
      field = :field

      data = Map.new([{ field, "value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "is invalid", validation: :inclusion } }],
               valid?: false
             } = Justify.validate_inclusion(data, field, ["another value"])
    end

    test "does not add an error if the value is not contained within enum" do
      field = :field

      value = "value"

      data = Map.new([{ field, value }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_inclusion(data, field, [value])
    end

    test "uses a custom error message when provided" do
      field = :field

      message = "message"

      data = Map.new([{ field, "value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { ^message, validation: :inclusion } }],
               valid?: false
             } = Justify.validate_inclusion(data, field, ["another value"], message: message)
    end

    test "does not add an error if value is `nil`" do
      field = :field

      data = Map.new([{ field, nil }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_inclusion(data, field, ["a value"])
    end
  end

  describe "validate_length/3" do
    test "adds an error if value's length does not exactly match `:is`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.graphemes(value)) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be %{count} character(s)", count: count, kind: :is, type: :string, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, is: count)
    end

    test "adds an error if value has a length less than `:min`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.graphemes(value)) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be at least %{count} character(s)", count: count, kind: :min, type: :string, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, min: count)
    end

    test "adds an error if value has a length greater than `:max`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.graphemes(value)) - 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be at most %{count} character(s)", count: count, kind: :max, type: :string, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, max: count)
    end

    test "adds an error if value's length does not exactly match `:is` when `:count` is `:codepoints`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.codepoints(value)) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be %{count} character(s)", count: count, kind: :is, type: :string, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, count: :codepoints, is: count)
    end

    test "adds an error if value has a length less than `:min` when `:count` is `:codepoints`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.codepoints(value)) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be at least %{count} character(s)", count: count, kind: :min, type: :string, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, count: :codepoints, min: count)
    end

    test "adds an error if value has a length greater than `:max` when `:count` is `:codepoints`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.codepoints(value)) - 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be at most %{count} character(s)", count: count, kind: :max, type: :string, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, count: :codepoints, max: count)
    end

    test "adds an error if value's length does not exactly match `:is` when `:count` is `:bytes`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = byte_size(value) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be %{count} byte(s)", count: count, kind: :is, type: :binary, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, count: :bytes, is: count)
    end

    test "adds an error if value has a length less than `:min` when `:count` is `:bytes`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = byte_size(value) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be at least %{count} byte(s)", count: count, kind: :min, type: :binary, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, count: :bytes, min: count)
    end

    test "adds an error if value has a length greater than `:max` when `:count` is `:bytes`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = byte_size(value) - 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should be at most %{count} byte(s)", count: count, kind: :max, type: :binary, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, count: :bytes, max: count)
    end

    test "adds an error if value is a list and does not exactly match `:is`" do
      field = :field

      value = ["é"]

      data = Map.new([{ field, value }])

      count = length(value) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should have %{count} item(s)", count: count, kind: :is, type: :list, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, is: count)
    end

    test "adds an error if value is a list with fewer items than `:min`" do
      field = :field

      value = ["é"]

      data = Map.new([{ field, value }])

      count = length(value) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should have at least %{count} item(s)", count: count, kind: :min, type: :list, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, min: count)
    end

    test "adds an error if value is a list with more items than `:max`" do
      field = :field

      value = ["é"]

      data = Map.new([{ field, value }])

      count = length(value) - 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "should have at most %{count} item(s)", count: count, kind: :max, type: :list, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, max: count)
    end

    test "does not add an error if value's length matches `:is` exactly" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.graphemes(value))

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_length(data, field, is: count)
    end

    test "does not add an error if value has a length less than `:min`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.graphemes(value)) - 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_length(data, field, min: count)
    end

    test "does not add an error if value has a length greater than `:max`" do
      field = :field

      value = "é"

      data = Map.new([{ field, value }])

      count = length(String.graphemes(value)) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_length(data, field, max: count)
    end

    test "does not add an error if value is `nil`" do
      field = :field

      data = Map.new([{ field, nil }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_length(data, field, is: 1)
    end

    test "does not add an error if value is an empty string" do
      field = :field

      data = Map.new([{ field, "" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_length(data, field, is: 1)
    end

    test "uses a custom error message when provided" do
      field = :field

      value = "é"

      message = "message"

      data = Map.new([{ field, value }])

      count = length(String.graphemes(value)) + 1

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { ^message, count: count, kind: :is, type: :string, validation: :length } }],
               valid?: false
             } = Justify.validate_length(data, field, is: count, message: message)
    end
  end

  describe "validate_required/3" do
    test "adds an error if value is `nil`" do
      field = :field

      data = %{}

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "can't be blank", validation: :required } }],
               valid?: false
             } = Justify.validate_required(data, field)
    end

    test "adds an error if value is an empty string" do
      field = :field

      data = Map.new([{ field, "" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "can't be blank", validation: :required } }],
               valid?: false
             } = Justify.validate_required(data, field)
    end

    test "adds an error if value is only whitespace and `:trim?` is `true`" do
      field = :field

      data = Map.new([{ field, " " }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [{ ^field, { "can't be blank", validation: :required } }],
               valid?: false
             } = Justify.validate_required(data, field, trim?: true)
    end

    test "adds multiple errors if a list of fields is provided" do
      field_a = :field_a
      field_b = :field_b

      data = %{}

      assert %Justify.Dataset{
               data: ^data,
               errors: [
                 { ^field_a, { "can't be blank", validation: :required } },
                 { ^field_b, { "can't be blank", validation: :required } }
                ],
               valid?: false
             } = Justify.validate_required(data, [field_a, field_b])
    end

    test "does not add an error if value is not nil or only whitespace" do
      field = :field

      data = Map.new([{ field, "value" }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_required(data, field)
    end

    test "does not add an error if value is only whitespace and `:trim?` is `false`" do
      field = :field

      data = Map.new([{ field, " " }])

      assert %Justify.Dataset{
               data: ^data,
               errors: [],
               valid?: true
             } = Justify.validate_required(data, field, trim?: false)
    end

    test "uses a custom error message when provided" do
      field = :field
      message = "message"

      data = %{}

      assert %Justify.Dataset{
               data: ^data,
               errors: [{^field, {^message, validation: :required}}],
               valid?: false
             } = Justify.validate_required(data, field, message: message)
    end
  end

  describe "validate_map/3" do
    test "validates every key in a map" do
      field = :name

      data = %{
        nested: %{
          one: %{name: "Name"},
          two: %{name: "N"}
        }
      }

      assert %Justify.Dataset{
               errors: [
                 {:nested,
                  [
                    two: [{^field, _}]
                  ]}
               ],
               valid?: false
             } =
               Justify.validate_map(data, :nested, fn v ->
                 v
                 |> Justify.validate_length(field, min: 2)
               end)
    end
  end
end
