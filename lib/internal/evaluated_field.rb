# frozen_string_literal: true

module EvaluatedField
  def evaluated_field(name, context = {})
    val = public_send(name)
    return unless val

    if val.is_a?(Proc)
      val.arity.zero? ? val.call : val.call(context)
    else
      val
    end
  end
end
