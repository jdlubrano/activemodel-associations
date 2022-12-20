# frozen_string_literal: true

module ActiveModel
  module Associations
    module StrictLoading
      def strict_loading_mode
        :all
      end

      def strict_loading?
        false
      end

      def strict_loading_n_plus_one_only?
        false
      end
    end
  end
end
