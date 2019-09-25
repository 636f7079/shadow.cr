class Shadow::Option
  property record : Parser::Record
  property table : Parser::Table
  property vault : Parser::Vault

  def initialize
    @record = Parser::Record.new
    @table = Parser::Table.new
    @vault = Parser::Vault.new
  end

  def parse(args : Array(String))
    OptionParser.parse args do |parser|
      parser.on("-i", "--summary-table", "") do
        table.action = Table::Action::Summary
      end
      parser.on("-c +", "") do |item|
        table.action = Table::Action::Create
        table.name = item
      end
      parser.on("-d +", "") do |item|
        table.action = Table::Action::Delete
        table.name = item
      end
      parser.on("-s +", "") do |item|
        table.action = Table::Action::Select
        table.name = item
      end
      parser.on("-r +", "") do |item|
        table.action = Table::Action::Rename
        table.name = item
      end
      parser.on("--create-table", "") do
        table.action = Table::Action::Create
      end
      parser.on("--delete-table", "") do
        table.action = Table::Action::Delete
      end
      parser.on("--select-table", "") do
        table.action = Table::Action::Select
      end
      parser.on("--rename-table", "") do
        table.action = Table::Action::Rename
      end
      parser.on("--decrypt", "") do
        record.action = Record::Action::Decrypt
      end
      parser.on("--create", "") do
        record.action = Record::Action::Create
      end
      parser.on("--delete", "") do
        record.action = Record::Action::Delete
      end
      parser.on("--update", "") do
        record.action = Record::Action::Update
      end
      parser.on("--search", "") do
        record.action = Record::Action::Search
      end
      parser.on("--detail", "") do
        record.action = Record::Action::Detail
      end
      parser.on("--resign", "") do
        record.action = Record::Action::ReSign
      end
      parser.on("--summary", "") do
        record.action = Record::Action::Summary
      end
      parser.missing_option do |flag|
        STDERR.puts "Missing Value: #{flag}"
        STDERR.puts parser ensure abort nil
      end
      parser.invalid_option do |flag|
        STDERR.puts "Invalid Option: #{flag}"
        STDERR.puts parser ensure abort nil
      end
    end
  end
end
