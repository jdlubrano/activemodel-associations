module ActiveModel::Associations
  module OverrideMethods
    extend ActiveSupport::Concern
    module ClassMethods
      # Returns the class for the provided +name+.
      #
      # It is used to find the class correspondent to the value stored in the polymorphic type column.
      # https://github.com/rails/rails/blob/01f58d62c2f31f42d0184e0add2b6aa710513695/activerecord/lib/active_record/inheritance.rb#L205
      def polymorphic_class_for(name)
        name.constantize
      end

      def generated_association_methods
        @generated_association_methods ||= begin
          mod = const_set(:GeneratedAssociationMethods, Module.new)
          include mod
          mod
        end
      end
      alias generated_feature_methods generated_association_methods \
        if ActiveRecord.version < Gem::Version.new('4.1')

      # override
      def dangerous_attribute_method?(_name)
        false
      end

      # dummy table name
      def pluralize_table_names
        to_s.pluralize
      end

      def clear_reflections_cache
        @__reflections = nil
      end

      def default_scopes
        []
      end

      protected

      def compute_type(type_name)
        if type_name.match(/^::/)
          # If the type is prefixed with a scope operator then we assume that
          # the type_name is an absolute reference.
          ActiveSupport::Inflector.constantize(type_name)
        else
          # Build a list of candidates to search for
          candidates = []
          name.scan(/::|$/) { candidates.unshift "#{::Regexp.last_match.pre_match}::#{type_name}" }
          candidates << type_name

          candidates.each do |candidate|
            constant = ActiveSupport::Inflector.constantize(candidate)
            return constant if candidate == constant.to_s
            # We don't want to swallow NoMethodError < NameError errors
          rescue NoMethodError
            raise
          rescue NameError
          end

          raise NameError.new("uninitialized constant #{candidates.first}", candidates.first)
        end
      end
    end

    # use by association accessor
    def association(name) # :nodoc:
      association = association_instance_get(name)
      if association.nil?
        reflection = self.class.reflect_on_association(name)
        association = if reflection.options[:active_model]
                        ActiveRecord::Associations::HasManyForActiveModelAssociation.new(self, reflection)
                      else
                        reflection.association_class.new(self, reflection)
                      end
        association_instance_set(name, association)
      end

      association
    end

    def read_attribute(attr_name)
      send(attr_name)
    end
    alias _read_attribute read_attribute

    # dummy
    def new_record?
      false
    end

    # dummy
    def violates_strict_loading?
      false
    end

    # dummy
    def strict_loading_n_plus_one_only?
      false
    end

    # dummy
    def strict_loading?
      false
    end

    # dummy
    def strict_loading_mode
      :all
    end

    private

    # override
    def validate_collection_association(reflection)
      if association = association_instance_get(reflection.name)
        if records = associated_records_to_validate_or_save(association, false, reflection.options[:autosave])
          records.each { |record| association_valid?(reflection, record) }
        end
      end
    end

    # use in Rails internal
    def association_instance_get(name)
      @association_cache[name]
    end

    # use in Rails internal
    def association_instance_set(name, association)
      @association_cache[name] = association
    end
  end
end
