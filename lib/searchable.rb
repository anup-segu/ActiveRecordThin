require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map do |key|
      "#{key} = ?"
    end.join(" AND ")

    results = DBConnection.execute(
      "SELECT *
      FROM #{self.table_name}
      WHERE #{where_line}",
      params.values
    )

    self.parse_all(results)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
