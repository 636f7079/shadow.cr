module Shadow::Parser
  alias NameEmail = Shield::Parser::NameEmail
  alias TabAction = Shadow::Table::Action
  alias RecAction = Shadow::Record::Action

  include Shield::Parser

  class Config
    include YAML::Serializable
    property database : String

    def initialize
      @database = String.new
    end

    def self.default(config : Config)
      config.database =
        ENV["HOME"] + "/Shadow/vault"
    end
  end

  class Table
    property action : TabAction
    property name : String

    def initialize
      @action = TabAction::Select
      @name = String.new
    end

    def set_name(set : String)
      @name = set
    end
  end

  class Record
    property action : RecAction
    property value : String
    property rowId : Int32
    property column : String

    def initialize
      @action = RecAction::Decrypt
      @value = String.new
      @rowId = 0_i32
      @column = String.new
    end

    def set_rowid(set : Int32)
      @rowId = set
    end

    def set_column(set : String)
      @column = set
    end

    def set_value(set : String)
      @value = set
    end
  end

  class Vault
    include JSON::Serializable
    property nameEmail : NameEmail
    property secureId : String
    property enablePin : Bool
    property idType : Bool
    property rowId : Int32
    property title : String
    property location : String
    property userName : String
    property email : String
    property pinCode : String
    property useSymbol : Bool
    property iterations : Int32
    property key_valid : Bool
    property length : Int32
    property secretKey : String
    property signature : String

    def initialize
      @nameEmail = NameEmail.new
      @secretKey = String.new
      @enablePin = false
      @idType = false
      @secureId = String.new
      @key_valid = false
      @rowId = 0_i32
      @title = String.new
      @userName = String.new
      @email = String.new
      @pinCode = String.new
      @useSymbol = true
      @iterations = 0_i32
      @length = 0_i32
      @location = String.new
      @signature = String.new
    end
  end
end
