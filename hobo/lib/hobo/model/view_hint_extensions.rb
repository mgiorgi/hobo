module Hobo
  module Model
    module ViewHintExtensions
      def human_attribute_name(attribute_key_name, opt={})
        view_hints_field_names = self.view_hints.field_names
        view_hints_field_names.include?(attribute_key_name.to_sym) ?
        view_hints_field_names[attribute_key_name.to_sym] : super
      end

      def view_hints
        class_name = "#{name}Hints"
        class_name.safe_constantize or Object.class_eval("class #{class_name} < Hobo::ViewHints; end; #{class_name}")
      end
    end
  end
end
