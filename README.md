# Active Record Thin

An ORM inspired by the functionality of ActiveRecord that lets users create ruby objects representing entries in SQL tables. This allows them the ability to update and create new entries for SQL tables in ruby.

This project relies on the use of the 'activesupport' and 'sqlite3' ruby gems.

## How to Use

You can use the SQL Object class to inherit properties from for whatever project you are working on. The class that inherits it will have the ability to access and update a SQL database.

Download the lib folder and require `SQLObject` as below:

```ruby
require_relative "./lib/sql_object"

class YOUR_MODEL < SQLObject
  # Your code goes here
end
```

## Features & Implementation

### SQL Object

The core implementation of this project depends on the `SQLObject` class. This class is a blue print for all of the functionality needed to create and update entries in a SQL table.

Each `SQLObject` is initialized by taking a params hash that is converted into properties of the object that correspond to the SQL table's columns.

```ruby
class SQLObject
  def initialize(params = {})
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
end
```

Each instance knows what columns are available because those values are stored at the class level.

```ruby
class SQLObject
  def self.columns
    @cols ||= DBConnection
          .execute2("SELECT * FROM #{table_name}")
          .first
          .map(&:to_sym)
  end
end
```

`SQLObject` has a `#save` instance method that when called will either insert a new entry into the SQL table or update that entry. `SQLObject` also has an `::all` class method that fetches all entries of the particular SQL table the class corresponds with.

### Querying

An important functionality of the ORM is the ability to query the database for specific entries rather than just finding all entries. This is done using the `::where` class method. It takes `params` hash as an argument which is parsed into a SQL query.

```ruby
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
  extend Searchable
end
```

### Associations

Another important functionality that was preserved in the project was the use of associations. Since SQL entries can reference other tables through foreign keys, this needed to be represented in the ORM itself.

An `AssocOptions` class sets up the backbone of the object relationship. It has a `foreign_key`, `primary_key`, and `class_name` instance variables to do this. The `foreign_key` points to the column name of the `SQLObject`, while the `primary_key` and `class_name` points to the column and table of the other `SQLObject` that is part of the association.

`BelongsToOptions` and `HasManyOptions` inherit from `AssocOptions` and set up the actual relationship between SQLObjects. The `Associable` module actually defines the `::belongs_to`, `::has_many`, `::has_one_through` methods that are available to the SQL object that set up association.

## Future Directions for the Project

In addition to the features already implemented, I plan to continue work on this project to improve on the functionality that it can provide.

### Has Many Through

Similar to the `::has_one_through` association available to SQLObject, this association would be available as well to fully integrate the availability of table relationships.

### Creating A Gem

To further improve usability, this library would be converted into a ruby gem so that it can be readily imported into a project (for ex. new Rails projects) and serve as a complete replacement for ActiveRecordLite in rails.
