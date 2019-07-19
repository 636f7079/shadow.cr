module Shadow::Render
  include Shield::Render
  extend self

  def move(from, to : String)
    puts String.build { |io|
      io << "Moved "
      io << from.colorize.yellow
      io << " -> ".colorize.green
      io << to.colorize.cyan
    }
  end

  def update(from, to : String)
    puts String.build { |io|
      io << "Updated "
      io << from.colorize.yellow
      io << " -> ".colorize.green
      io << to.colorize.cyan
    }
  end

  def rename(from, to : String)
    puts String.build { |io|
      io << "Renamed "
      io << from.colorize.yellow
      io << " -> ".colorize.green
      io << to.colorize.cyan
    }
  end

  def bind(from, to : String)
    puts String.build { |io|
      io << "Bind "
      io << from.colorize.yellow
      io << " -> ".colorize.green
      io << to.colorize.cyan
    }
  end

  def create(text : String)
    puts String.build { |io|
      io << "Created ".colorize.green
      io << text
    }
  end

  def destroy(text : String)
    puts String.build { |io|
      io << "Destroy ".colorize.red
      io << text
    }
  end

  def delete(text : String)
    puts String.build { |io|
      io << "Deleted ".colorize.red
      io << text
    }
  end

  def reset(text : String)
    puts String.build { |io|
      io << "Reset ".colorize.yellow
      io << text
    }
  end

  def error(text : String | Nil)
    puts String.build { |io|
      io << "Error ".colorize.red
      text.try { |value| io << value }
    }
  end

  def select(text : String)
    puts String.build { |io|
      io << "Selected ".colorize.green
      io << text
    }
  end

  def enter_invalid
    puts String.build { |io|
      io << "Enter Invalid, Please try again.".colorize.red
    }
  end

  def show_record(vault : Parser::Vault)
    Render.final "Secure_Id", vault.secureId
    Render.final "TitleName", vault.title
    Render.final "_Location", vault.location
    Render.final "_UserName", vault.userName
    Render.final "SecretKey", vault.secretKey
    Render.final "__Email__", vault.email
    Render.final "_PinCode_", vault.pinCode
    Render.final "Key_Valid", vault.key_valid.to_s
  end

  def record_headings
    [["RowId", "Title", "Location",
      "UserName", "Email", "PinCode"],
    ["RowId", "Title", "Location",
     "UserName", "Email", "PinCode",
     "Symbol", "Length", "Iterations"]]
  end

  def row_record(vault : Parser::Vault)
    [[vault.rowId, vault.title,
      vault.location, vault.userName,
      vault.email, vault.pinCode],
    [vault.rowId, vault.title,
     vault.location, vault.userName,
     vault.email, vault.pinCode,
     vault.useSymbol, vault.length,
     vault.iterations]]
  end

  def show_all_records(vault, type : Record::Action)
    case type
    when Record::Action::Summary
      terminal_table = TerminalTable.new
      terminal_table.headings = record_headings.first
      vault.each do |record|
        terminal_table << row_record(record).first
      end ensure puts terminal_table.render
    when Record::Action::Detail
      terminal_table = TerminalTable.new
      terminal_table.headings = record_headings.last
      vault.each do |record|
        terminal_table << row_record(record).last
      end ensure puts terminal_table.render
    end
  end

  def tables_summary(list : Array(Tuple(String, Int32)))
    terminal_table = TerminalTable.new
    terminal_table.headings = ["TableName", "RowCount"]
    list.each { |n| terminal_table << [n.first, n.last] }
    puts terminal_table.render
  end
end
