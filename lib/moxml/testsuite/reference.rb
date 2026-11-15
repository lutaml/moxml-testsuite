# frozen_string_literal: true

module Moxml
  module TestSuite
    # The moxml-backed reference facade: every certification face
    # answered through moxml itself. Any moxml install certifies its
    # own engine with it:
    #
    #   report = Moxml::TestSuite.run(Moxml::TestSuite::Reference.new)
    #   puts report
    #   report.passed? # => true
    #
    # Pin the engine explicitly when the host carries several:
    #
    #   Moxml::TestSuite::Reference.new(adapter: :leptris)
    #
    # The decision faces (lexical, wildcard, regex, entity registry)
    # are engine-free - moxml answers them in pure Ruby, the model's
    # committed answers. The DOM faces (parse, serialize, canonicalize,
    # validate_xsd) run on the selected adapter: that is the point -
    # the suite certifies the ENGINE's observable behavior against
    # the model.
    class Reference
      def initialize(adapter: nil)
        require "moxml"
        @context = adapter ? Moxml.new(adapter) : Moxml.new
        # The dataset pins the model's committed emitter shape:
        # compact, no inter-element indentation.
        @context.config.default_indent = 0
      end

      attr_reader :context

      # -- DOM faces -------------------------------------------------

      def parse(xml)
        @context.parse(xml)
      end

      def serialize(doc)
        doc.to_xml
      end

      def canonicalize(doc)
        Moxml::C14n.canonicalize(doc)
      end

      def validate_xsd(schema_xml, instance)
        @context.xsd(schema_xml).validate(instance)
      end

      # -- decision faces (engine-free) ------------------------------

      def lexical_valid?(type_name, lexical)
        Moxml::XSD::BuiltinLexical.valid?(type_name, lexical)
      end

      def regex_translates?(pattern)
        Moxml::XSD::SchemaRules::XsdRegex.translate(pattern)
      end

      def wildcard_covers?(constraint:, process:, not_namespace:,
                           not_qname:, item_namespace:)
        wildcard(constraint, process, not_namespace, not_qname)
          .covers?(item_namespace.to_sym)
      end

      def wildcard_exclusion?(constraint:, process:, not_namespace:,
                              not_qname:, item_namespace:, item_name:,
                              defined:, sibling_names:)
        answer = wildcard(constraint, process, not_namespace, not_qname)
          .negative_exclusion(item_name, item_namespace.to_sym,
                              defined: defined,
                              sibling_names: sibling_names)
        answer&.to_s
      end

      def entity_declared?(seed:, name:)
        registry(seed).declared?(name)
      end

      def entity_codepoint(seed:, name:)
        registry(seed).codepoint_for_name(name)
      end

      def entity_names(seed:, codepoint:)
        registry(seed).names_for_codepoint(codepoint)
      end

      def entity_primary_name(seed:, codepoint:)
        registry(seed).primary_name_for_codepoint(codepoint)
      end

      def entity_standard?(seed:, codepoint:)
        registry(seed).standard_entity?(codepoint)
      end

      def entity_should_restore?(seed:, codepoint:, restore_entities:,
                                 restoration_mode:)
        registry(seed).should_restore?(
          codepoint, config: restoration_config(restore_entities,
                                                restoration_mode)
        )
      end

      private

      def wildcard(constraint, process, not_namespace, not_qname)
        Moxml::XSD::SchemaRules::Wildcard.new(
          constraint, process,
          not_namespace: not_namespace,
          not_qname: Array(not_qname).join(" "),
          element: nil
        )
      end

      def registry(seed)
        Moxml::EntityRegistry.new(mode: :custom, entity_provider: -> { seed })
      end

      def restoration_config(restore_entities, restoration_mode)
        config = Moxml::Config.new
        config.restore_entities = restore_entities
        config.entity_restoration_mode = restoration_mode.to_sym
        config
      end
    end
  end
end
