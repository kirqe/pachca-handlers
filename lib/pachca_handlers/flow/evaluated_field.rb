# frozen_string_literal: true

require_relative 'callback_context'

module PachcaHandlers
  module Flow
    module EvaluatedField
      def evaluated_field(name, context = {})
        val = public_send(name)
        return unless val

        if val.is_a?(Proc)
          handler = context[:handler]
          if val.arity.zero?
            handler ? handler.instance_exec(&val) : val.call
          else
            ctx = CallbackContext.new(context)
            handler ? handler.instance_exec(ctx, &val) : val.call(ctx)
          end
        else
          val
        end
      end
    end
  end
end
