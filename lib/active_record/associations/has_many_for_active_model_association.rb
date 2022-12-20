module ActiveRecord::Associations
  class HasManyForActiveModelAssociation < HasManyAssociation
    # remove conditions: owner.new_record?, foreign_key_present?
    def find_target?
      !loaded? && klass
    end

    # no dependent action
    def null_scope?
      false
    end

    # not support counter_cache
    def empty?
      if loaded?
        size.zero?
      else
        @target.blank? && !scope.exists?
      end
    end

    # full replace simplely
    def replace(other_array)
      original_target = load_target.dup
      other_array.each { |val| raise_on_type_mismatch!(val) }
      target_ids = reflection.options[:target_ids]
      owner[target_ids] = other_array.map(&:id)

      old_records = original_target - other_array
      old_records.each do |record|
        @target.delete(record)
      end

      other_array.each do |record|
        if index = @target.index(record)
          @target[index] = record
        else
          @target << record
        end
      end
      @target
    end

    # no need transaction
    def concat(*records)
      load_target
      flatten_records = records.flatten
      flatten_records.each { |val| raise_on_type_mismatch!(val) }
      target_ids = reflection.options[:target_ids]
      owner[target_ids] ||= []
      owner[target_ids].concat(flatten_records.map(&:id))

      flatten_records.each do |record|
        if index = @target.index(record)
          @target[index] = record
        else
          @target << record
        end
      end

      target
    end

    def find_target
      if violates_strict_loading? && owner.validation_context.nil?
        Base.strict_loading_violation!(owner: owner.class, reflection: reflection)
      end
      scope = self.scope
      return scope.to_a if skip_statement_cache?(scope)

      reflection.association_scope_cache(klass, owner) do |params|
        as = AssociationScope.create { params.bind }
        target_scope.merge!(as.scope(self))
      end
      target_scope.to_a
    end

    def merge_target_lists(persisted, memory)
      return persisted if memory.empty?
      memory

      # persisted.map! do |record|
      #   if mem_record = memory.delete(record)

      #     ((record.attribute_names & mem_record.attribute_names) - mem_record.changed_attribute_names_to_save).each do |name|
      #       mem_record[name] = record[name]
      #     end

      #     mem_record
      #   else
      #     record
      #   end
      # end

      # persisted + memory.reject(&:persisted?)
    end

    private

    def get_records
      return scope.to_a if reflection.scope_chain.any?(&:any?)

      target_ids = reflection.options[:target_ids]
      klass.where(id: owner[target_ids]).to_a
    end
  end
end
