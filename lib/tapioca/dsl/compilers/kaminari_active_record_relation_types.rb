# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Compilers
      class KaminariActiveRecordRelationTypes < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(ActiveRecord::Base) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            ActiveRecord::Base.descendants.select(&:table_exists?)
          end
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |model|
            relations = ["PrivateRelation", "PrivateAssociationRelation", "PrivateCollectionProxy"]
            methods_to_forward = ["where", "order", "per"]

            paginated_classes =
              relations.map do |relation|
                klass_name = "Paginated#{relation}"
                model.create_class(klass_name, superclass_name: relation) do |klass|
                  klass.create_include("Kaminari::PageScopeMethods")

                  methods_to_forward.each do |method|
                    klass.create_method(
                      method,
                      parameters: [create_rest_param("args", type: "T.untyped")],
                      return_type: klass_name,
                    )
                  end
                end
              end

            model.create_constant("PaginatedRelationType", value: <<~TYPE.strip)
              T.type_alias { T.any(#{paginated_classes.join(", ")}) }
            TYPE
          end
        end
      end
    end
  end
end
