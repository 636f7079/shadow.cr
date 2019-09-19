class Shadow::Table
  property database : SQLite
  property option : Option

  enum Action
    Unknown
    Create
    Delete
    Select
    Rename
    Summary
  end

  def initialize(@option, @database : SQLite)
    @option.parse ARGV
  end

  def initialize(@option, path : String)
    @option.parse ARGV
    @database = SQLite.new path
  end

  def self.new(option : Option)
    Config.load_config do |config|
      new(option, config.database).dispatch
    end
  end

  def dispatch
    case option.table.action
    when Action::Summary
      summary_handler
    when Action::Create
      create_handler
    when Action::Delete
      delete_handler
    when Action::Rename
      rename_handler
    when Action::Select
      select_handler
    when Action::Unknown
    end
  end

  def show_table_summary(names, counts : Array(Int32))
    Render.tables_summary names.zip(counts) if option.table.name.empty?
  end

  def input_table_name_not_exist(table_names : Array(String), ask : String)
    return yield option.table.name unless table_names.includes? option.table.name

    loop do
      print Render.enter ask ensure input = Utils.input
      break yield input unless table_names.includes? input
      puts "The Input TableName Already exists, Please try again."
    end
  end

  def input_table_name_exist(table_names : Array(String), ask : String)
    return yield option.table.name if table_names.includes? option.table.name

    loop do
      print Render.enter ask ensure input = Utils.input
      break yield input if table_names.includes? input
      puts "The Input TableName Does not Exist, Please try again."
    end
  end

  def fetch_table_names_with_counts
    database.fetch_table_names do |success?, names, message|
      return Render.error message unless success?
      database.fetch_table_counts names do |success?, counts, message|
        return Render.error message unless success?
        return yield names, counts
      end
    end
  end

  def summary_handler
    fetch_table_names_with_counts do |names, counts|
      Render.tables_summary names.zip(counts)
    end
  end

  def select_handler
    fetch_table_names_with_counts do |names, counts|
      show_table_summary names, counts
      input_table_name_exist(names, "TableName") do |table_name|
        option.table.set_name table_name
        Render.select table_name
        Record.launch option, database
      end
    end
  end

  def create_handler
    fetch_table_names_with_counts do |names, counts|
      show_table_summary names, counts
      input_table_name_not_exist(names, "TableName") do |table_name|
        database.create_table table_name do |success?, message|
          return Render.error message unless success?
          Render.create table_name
        end
      end
    end
  end

  def delete_handler
    fetch_table_names_with_counts do |names, counts|
      show_table_summary names, counts
      input_table_name_exist(names, "TableName") do |table_name|
        database.drop_table table_name do |success?, message|
          return Render.error message unless success?
          Render.delete table_name
        end
      end
    end
  end

  def rename_handler
    fetch_table_names_with_counts do |names, counts|
      show_table_summary names, counts
      input_table_name_exist(names, "BeforeName") do |before_name|
        input_table_name_not_exist(names, "_AfterName") do |after_name|
          database.rename_table(before_name, after_name) do |success?, message|
            return Render.error message unless success?
            Render.rename before_name, after_name
          end
        end
      end
    end
  end
end
