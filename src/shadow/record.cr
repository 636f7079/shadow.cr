class Shadow::Record
  property database : SQLite
  property option : Option

  enum Action
    Unknown
    Decrypt
    Create
    Delete
    Update
    Search
    Detail
    ReSign
    Summary
  end

  def initialize(@option, @database : SQLite)
  end

  def initialize(@option, path : String)
    @database = SQLite.new path
  end

  def self.launch(option : Option, path : String)
    new(option, path).dispatch
  end

  def self.launch(option : Option, database : SQLite)
    new(option, database).dispatch
  end

  def dispatch
    case option.record.action
    when Action::Summary
      summary_handler
    when Action::Decrypt
      decrypt_handler
    when Action::Create
      create_handler
    when Action::Delete
      delete_handler
    when Action::Update
      update_handler
    when Action::ReSign
      resign_handler
    when Action::Search
      search_handler
    when Action::Detail
      detail_handler
    when Action::Unknown
    end
  end

  def setup_create
    vault = option.vault
    Setup.title_name vault
    Setup.location vault
    Setup.user_name vault
    Setup.email vault
    Setup.pin_code vault
    Setup.use_symbol vault
    Setup.length vault
    Setup.iterations vault
    Setup.signature vault
    yield
  end

  def set_column_with_value(record : Parser::Record)
    Render.enter "Column"
    record.set_column Config::Utils.input
    Render.enter "_Value"
    record.set_value Config::Utils.input
    yield
  end

  def set_column_with_rowid(record : Parser::Record)
    set_rowid record do
      Render.enter "Column"
      record.set_column Config::Utils.input
      yield
    end
  end

  def set_rowid(record : Parser::Record)
    loop do
      Render.enter "_RowId"
      i = Config::Utils.input
      if i.to_i?
        record.set_rowid i.to_i
        break yield
      end
      Render.enter_invalid
    end
  end

  def extract_shield(vault : Parser::Vault)
    Render.ask_master_key do |master_key|
      builder = Shield::Builder.new Shield::Option.from_json vault.to_json
      vault.secureId = Shield::Utils.create_id vault.title
      builder.create_key(master_key, vault.secureId) do |done?, data|
        vault.secretKey = data if done?
        builder.create_pin! data do |pin|
          hmac = OpenSSL::PKCS5.pbkdf2_hmac secret: data, salt: pin,
            iterations: vault.iterations, algorithm: OpenSSL::Algorithm::SHA512
          vault.key_valid = true if hmac.hexstring == vault.signature
        end if done?
        builder.create_pin! data do |pin|
          vault.pinCode = pin
        end if done?
        builder.create_name!(data, vault.secureId) do |done?, name|
          vault.userName = name if done?
        end if done?
        builder.create_email!(data, vault.secureId) do |done?, email|
          vault.email = email if done?
        end if done?
      end ensure yield
    end
  end

  def choose_single_record
    database.fetch_record_by_column(option.table.name, option.record) do |success?, data, message|
      return Render.error message unless success?
      abort "No item Found that Match".colorize.red if data.empty?
      if 1_i32 == data.size
        option.record.rowId = data.first.rowId
        return yield data.first
      end
      Render.show_all_records data, Action::Summary
      set_rowid option.record do
        database.fetch_record_by_rowid(option.table.name, option.record) do |success?, vault, message|
          return Render.error message unless success?
          yield vault
        end
      end
    end
  end

  def decrypt_handler
    database.fetch_limit_table(option.table.name, "25") do |success?, data, message|
      return Render.error message unless success?
      Render.show_all_records data, Action::Summary if success?
      set_column_with_value option.record do
        choose_single_record { |vault| extract_shield(vault) { Render.show_record vault } }
      end
    end
  end

  def resign_handler
    database.fetch_limit_table(option.table.name, "25") do |success?, data, message|
      return Render.error message unless success?
      Render.show_all_records data, Action::Summary if success?
      set_column_with_value option.record do
        choose_single_record do |vault|
          option.record.column = "signature" ensure before = vault.signature
          Setup.signature vault
          option.record.set_value vault.signature
          database.update_column_by_rowid(option.table.name, option.record) do |success?, message|
            return Render.error message unless success?
            Render.update before, option.record.value
          end
        end
      end
    end
  end

  def update_handler
    database.fetch_limit_table(option.table.name, "25") do |success?, data, message|
      return Render.error message unless success?
      Render.show_all_records data, Action::Summary if success?
      set_column_with_value option.record do
        choose_single_record do |vault|
          database.fetch_column_by_rowid(option.table.name, option.record) do |success?, data, message|
            return Render.error message unless success?
            data = "Nil" if data.empty?
            print String.build { |io| io << option.record.column << ":[" << data << "]: " }
            option.record.set_value Config::Utils.input
            database.update_column_by_rowid(option.table.name, option.record) do |success?, message|
              return Render.error message unless success?
              Render.update data, option.record.value
            end
          end
        end
      end
    end
  end

  {% for item in ["summary", "detail"] %}
    def {{item.id}}_handler
      database.fetch_table option.table.name do |success?, data, message|
        return Render.error message unless success?
        Render.show_all_records data, Action::{{item.id.capitalize}}
      end
    end
    {% end %}

  def search_handler
    set_column_with_value option.record do
      database.search_table(option.table.name, option.record) do |success?, data, message|
        return Render.error message unless success?
        Render.show_all_records data, Action::Summary
      end
    end
  end

  def create_handler
    setup_create do
      database.create_record(option.table.name, option.vault) do |success?, message|
        return Render.error message unless success?
        Render.create option.vault.title
      end
    end
  end

  def delete_handler
    database.fetch_limit_table(option.table.name, "25") do |success?, data, message|
      return Render.error message unless success?
      Render.show_all_records data, Action::Summary if success?
      set_column_with_value option.record do
        choose_single_record do |vault|
          option.record.rowId = vault.rowId
          database.delete_record(option.table.name, option.record) do |success?, message|
            Render.error message unless success?
            Render.delete String.build { |io| io << "RowId: " << option.record.rowId.to_s }
          end
        end
      end
    end
  end
end
