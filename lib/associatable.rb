require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    # set up the basic elements of a belongs_to association

    @foreign_key ||= "#{name}_id".to_sym
    @primary_key ||= :id
    @class_name ||= name.to_s.camelize

    options.each do |attr_name, value|
      instance_variable_set("@"+attr_name.to_s, value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # set up the basic elements of a has_many association

    @foreign_key ||= "#{self_class_name.underscore.downcase}_id".to_sym
    @primary_key ||= :id
    @class_name ||= name.to_s.singularize.camelize


    options.each do |attr_name, value|
      instance_variable_set("@"+attr_name.to_s, value)
    end
  end
end

module Associatable
  def belongs_to(name, options = {})
    # belongs_to association
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      params = {}
      params[options.primary_key] = self.attributes[options.primary_key]
      options.model_class.where(params).first
    end
  end

  def has_many(name, options = {})
    # has_many association
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      params = {}
      params[options.foreign_key] = self.attributes[options.primary_key]
      options.model_class.where(params)
    end
  end

  def assoc_options
    @assoc_options ||= {}

    # define_method(name) do
    #   @assoc_options[name]
    # end
  end
end

class SQLObject
  # Extend Associatable for SQL Object
  extend Associatable
end
