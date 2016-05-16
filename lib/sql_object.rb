require_relative 'db_connection'
require_relative 'searchable'
require 'active_support/inflector'

class SQLObject
  def self.columns
    # Create an instance variables array for each column of a table
    @cols ||= DBConnection
          .execute2("SELECT * FROM #{table_name}")
          .first
          .map(&:to_sym)
  end

  def self.finalize!
    # Convert the instance variables array into actual instance variables
    columns.each do |col|
      define_method(col) do
        attributes[col]
      end

      set_name = col.to_s+"="
      define_method(set_name) do |value|
        attributes[col] = value
      end

    end
  end

  def self.table_name=(table_name)
    # Define table name that the SQL object references
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    # Find all entries in a table and convert them into SQL objects
    results =
      DBConnection.execute("SELECT #{table_name}.* FROM #{table_name}")

    parse_all(results)
  end

  def self.parse_all(results)
    # All entries in results are converted into SQL objects
    results.map do |result|
      new(result)
    end
  end

  def self.find(id)
    # Find an entry by id
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        '#{table_name}'
      WHERE
        id = '#{id}'
    SQL

    self.parse_all(results).first
  end

  def initialize(params = {})
    # initialize a SQL object
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym unless attr_name.is_a?(Symbol)

      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end

      param = {attr_name => value}
      attr_set = attr_name.to_s + "="
      self.send(attr_set, value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |col|
      self.send(col)
    end
  end

  def insert
    # Create a new entry in the table
    cols = self.class.columns
    question_marks = ["?"]*cols.length
    question_marks = question_marks.join(", ")
    col_names = cols.join(", ")
    insert_helper = self.class.table_name + " (#{col_names})"
    DBConnection.execute(
        "INSERT INTO #{insert_helper}
        VALUES ( #{question_marks} )",
         attribute_values
    )

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    # Update an exiting entry in the table
    set_helper = self.class.columns.map do |col|
      "#{col} = ?"
    end.join(", ")
    DBConnection.execute(
      "UPDATE #{self.class.table_name}
      SET #{set_helper}
      WHERE id = #{self.id}",
      attribute_values
    )
  end

  def save
    # Update or insert an SQL object
    # (depending on if it existings in the table)
    if id.nil?
      insert
    else
      update
    end
  end
end
