class Shadow::SQLite
  alias Message = String | Nil
  getter location
  property database : DB::Database

  def initialize(location : String)
    @database = DB.open "sqlite3://" + location
  end

  def exec(database, query, *args)
    begin
      database.exec query, *args
      yield true, String.new
    rescue ex
      yield false, ex.message
    end
  end

  def query(database, query, *args)
    begin
      yield true, database
        .query(query, *args),
        String.new
    rescue ex
      yield false, nil, ex.message
    end
  end

  def create_table(table : String)
    exec database, String.build { |io|
      io << "CREATE TABLE IF NOT EXISTS "
      io << table << " (title TEXT, "
      io << "location TEXT, userName "
      io << "TEXT, email TEXT, pinCode "
      io << "TEXT, useSymbol INTEGER, "
      io << "length INTEGER, iterations "
      io << "INTEGER, nameWithEmail BLOB, "
      io << "signature TEXT)"
    } do |success?, message|
      yield success?, message
    end
  end

  def read_rows(vault : Parser::Vault, rows)
    vault.rowId = rows.read Int32
    vault.title = rows.read String
    vault.location = rows.read String
    vault.userName = rows.read String
    vault.email = rows.read String
    vault.pinCode = rows.read String
    vault.useSymbol = rows.read Bool
    vault.length = rows.read Int32
    vault.iterations = rows.read Int32
    vault.nameEmail = Parser::NameEmail
      .from_json String
      .new rows.read Slice(UInt8)
    vault.signature = rows.read String
  end

  def unpack_vault(vault : Parser::Vault, rows)
    read_rows vault, rows
    if vault.pinCode == "[protected]"
      vault.enablePin = true
    end
  end

  def search_table(table, record : Parser::Record)
    fetch = [] of Parser::Vault
    query database, String.build { |io|
      io << "SELECT ROWID, * FROM "
      io << table << " WHERE "
      io << record.column << " LIKE"
      io << "\"" << record.value << "\""
    } do |success?, rows, message|
      unless success?
        return yield false, fetch, String.new
      end
      rows.try do |value|
        value.each do
          vault = Parser::Vault.new
          unpack_vault vault, value
          fetch << vault
        end
      end
      yield true, fetch, String.new
    end
  end

  def fetch_limit_table(table, limit : String)
    fetch = [] of Parser::Vault
    query database, String.build { |io|
      io << "SELECT ROWID, * FROM "
      io << table << " LIMIT " << limit
    } do |success?, rows, message|
      unless success?
        return yield false, fetch, String.new
      end
      rows.try do |value|
        value.each do
          vault = Parser::Vault.new
          unpack_vault vault, value
          fetch << vault
        end
      end
      yield true, fetch, String.new
    end
  end

  def fetch_table(table : String)
    fetch = [] of Parser::Vault
    query database, String.build { |io|
      io << "SELECT ROWID, * FROM " << table
    } do |success?, rows, message|
      unless success?
        return yield false, fetch, String.new
      end
      rows.try do |value|
        value.each do
          vault = Parser::Vault.new
          unpack_vault vault, value
          fetch << vault
        end
      end
      yield true, fetch, String.new
    end
  end

  def drop_table(table : String)
    exec database, String.build { |io|
      io << "DROP TABLE IF EXISTS " << table
    } do |success?, message|
      yield success?, message
    end
  end

  def rename_table(before, after : String)
    exec database, String.build { |io|
      io << "ALTER TABLE " << before
      io << " RENAME TO " << after
    } do |success?, message|
      yield success?, message
    end
  end

  def create_record(table, vault : Parser::Vault)
    exec database, String.build { |io|
      io << "INSERT INTO " << table
      io << " VALUES "
      io << "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    }, vault.title, vault.location,
      vault.userName, vault.email,
      vault.pinCode, vault.useSymbol,
      vault.length, vault.iterations,
      vault.nameEmail.to_json.to_slice,
      vault.signature do |success?, message|
      yield success?, message
    end
  end

  def delete_record(table, record : Parser::Record)
    exec database, String.build { |io|
      io << "DELETE FROM " << table
      io << " WHERE ROWID = " << "\""
      io << record.rowId.to_s << "\""
    } do |success?, message|
      yield success?, message
    end
  end

  def fetch_record_by_column(table, record : Parser::Record)
    fetch = [] of Parser::Vault
    query database, String.build { |io|
      io << "SELECT ROWID, * FROM "
      io << table << " WHERE "
      io << record.column << " = "
      io << "\"" << record.value << "\""
    } do |success?, rows, message|
      unless success?
        return yield false, fetch, String.new
      end
      rows.try do |value|
        value.each do
          vault = Parser::Vault.new
          unpack_vault vault, value
          fetch << vault
        end
      end
      yield true, fetch, String.new
    end
  end

  def update_column_by_rowid(table, record : Parser::Record)
    exec database, String.build { |io|
      io << "UPDATE " << table << " SET "
      io << record.column << " = "
      io << "\"" << record.value << "\""
      io << " WHERE ROWID = " << record.rowId
    } do |success?, message|
      yield success?, message
    end
  end

  def fetch_record_by_rowid(table, record : Parser::Record)
    fetch = Parser::Vault.new
    query database, String.build { |io|
      io << "SELECT ROWID, * FROM " << table
      io << " WHERE ROWID = " << "\""
      io << record.rowId.to_s << "\""
    } do |success?, rows, message|
      unless success?
        return yield false, fetch, String.new
      end
      rows.try do |value|
        value.each do
          vault = Parser::Vault.new
          unpack_vault vault, value
          fetch = vault
        end
      end
      yield true, fetch, String.new
    end
  end

  def fetch_column_by_rowid(table, record : Parser::Record)
    fetch = String.new
    query database, String.build { |io|
      io << "SELECT " << record.column
      io << " FROM " << table
      io << " WHERE ROWID = " << "\""
      io << record.rowId.to_s << "\""
    } do |success?, rows, message|
      unless success?
        return yield false, fetch, String.new
      end
      rows.try do |value|
        value.each do
          fetch = value.read String
        end
        yield true, fetch, String.new
      end
    end
  end

  def fetch_table_names
    fetch = [] of String
    query database, String.build { |io|
      io << "SELECT NAME FROM sqlite_master"
    } do |success?, rows, message|
      unless success?
        return yield false, fetch, String.new
      end
      rows.try do |value|
        value.each do
          fetch << value.read String
        end
        yield true, fetch, String.new
      end
    end
  end

  def fetch_table_counts(names : Array(String))
    fetch = [] of Int32
    names.each do |name|
      query database, String.build { |io|
        io << "SELECT COUNT(*) FROM " << name
      } do |success?, rows, message|
        unless success?
          return yield false, fetch, String.new
        end
        rows.try do |value|
          value.each do
            fetch << value.read Int32
          end
        end
      end
    end
    yield true, fetch, String.new
  end
end
