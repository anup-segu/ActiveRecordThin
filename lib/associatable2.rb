require_relative 'associatable'

module Associatable

  def has_one_through(name, through_name, source_name)
    # has_one_through association setup
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options =
        through_options.model_class.assoc_options[source_name]

      params = {}
      params[source_options.foreign_key] = through_options.model_class
      source_options
        .model_class
        .where({id: self.attributes[through_options.foreign_key]})
        .first
    end
  end
end
