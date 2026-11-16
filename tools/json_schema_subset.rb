# frozen_string_literal: true

# Gem-free JSON-Schema subset validator. Implements exactly the
# keywords schema/test.schema.json uses and fails CLOSED: any keyword
# it does not implement raises, so the schema can never silently
# under-validate. Runs with plain `ruby`, no bundle.
module JsonSchemaSubset
  ANNOTATIONS = %w[$schema $id title description].freeze
  HANDLED_JOINTLY = %w[properties additionalProperties].freeze
  SKIP_KEYWORDS = (ANNOTATIONS + ["$defs"] + HANDLED_JOINTLY).freeze

  class UnsupportedKeyword < StandardError; end

  module_function

  # @return [Array<String>] error messages; empty when valid
  def validate(schema, instance, path = "$", root = nil)
    root ||= schema
    unless schema.is_a?(Hash)
      raise UnsupportedKeyword,
            "schema must be a Hash at #{path}"
    end

    if schema["$ref"]
      return validate(deref(schema["$ref"], root), instance, path,
                      root)
    end

    errors = []
    schema.each do |keyword, value|
      case keyword
      when *SKIP_KEYWORDS then nil
      when "type" then check_type(value, instance, path, errors)
      when "enum"
        errors << "#{path}: not in enum" unless value.include?(instance)
      when "const"
        errors << "#{path}: != const #{value.inspect}" unless instance == value
      when "pattern"
        if instance.is_a?(String) && !instance.match?(Regexp.new(value))
          errors << "#{path}: does not match #{value.inspect}"
        end
      when "required"
        missing = Array(value).reject do |k|
          instance.is_a?(Hash) && instance.key?(k)
        end
        errors.concat(missing.map do |k|
          "#{path}: missing required #{k.inspect}"
        end)
      when "items"
        if instance.is_a?(Array)
          instance.each_with_index do |el, i|
            errors.concat(validate(value, el, "#{path}[#{i}]", root))
          end
        end
      when "minItems"
        if instance.is_a?(Array) && instance.length < value
          errors << "#{path}: fewer than #{value} items"
        end
      when "oneOf"
        passing = value.count do |alt|
          validate(alt, instance, path, root).empty?
        end
        unless passing == 1
          errors << "#{path}: matches #{passing} oneOf branches, want exactly 1"
        end
      else
        raise UnsupportedKeyword,
              "keyword #{keyword.inspect} at #{path} is not implemented"
      end
    end

    if instance.is_a?(Hash)
      props = schema["properties"] || {}
      props.each do |key, sub|
        next unless instance.key?(key)

        errors.concat(validate(sub, instance[key], "#{path}.#{key}", root))
      end
      if schema["additionalProperties"] == false
        extra = instance.keys - props.keys
        unless extra.empty?
          errors << "#{path}: unexpected keys #{extra.inspect}"
        end
      end
    end
    errors
  end

  def deref(ref, root)
    unless ref.is_a?(String) && ref.start_with?("#/$defs/")
      raise UnsupportedKeyword,
            "only #/$defs/... refs are implemented (#{ref.inspect})"
    end

    root.dig(*ref.split("/")[1..]) or
      raise UnsupportedKeyword, "unresolvable ref #{ref.inspect}"
  end

  TYPE_CHECKS = {
    "object" => Hash,
    "array" => Array,
    "string" => String,
    "integer" => Integer,
    "number" => Numeric,
  }.freeze

  def check_type(types, instance, path, errors)
    Array(types).each do |t|
      ok = if TYPE_CHECKS.key?(t)
             instance.is_a?(TYPE_CHECKS[t])
           elsif t == "boolean"
             instance.equal?(true) || instance.equal?(false)
           elsif t == "null"
             instance.nil?
           else
             raise UnsupportedKeyword, "type #{t.inspect} is not implemented"
           end
      return if ok
    end
    errors << "#{path}: not #{Array(types).join('|')} (got #{instance.class})"
  end
end
