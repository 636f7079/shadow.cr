module Shadow::Setup
  extend self

  alias Type = String | Int32 | Bool

  {% for item in ["integer", "boolean", "string"] %}
  def {{item.id}}(desc, option : NamedTuple)
    loop do
      Render.enter desc ensure input = Utilit.input
      case [input.empty?, option[:allow_empty]]
      when [true, false]
        puts "Input can not be empty, Please try again.".colorize.red
      when [true, true] 
       break yield option[:default]
      else
        {% if "integer" == item.id %}
          min, max = option[:min], option[:max]
          if input.to_i? && input.to_i > min && input.to_i < max
            break yield input.to_i
          end
          puts "Input Invalid, Please try again.".colorize.red
        {% elsif "boolean" == item.id %}
          if input == "true" || input == "false"
            break yield input == "true" ? true : false
          end
          puts "Input Invalid, Please try again.".colorize.red
        {% elsif "string" == item.id %} break yield input
        {% end %}
      end
    end
  end
  {% end %}

  def title_name(vault : Parser::Vault)
    string("TitleName(e.g. dropbox | Must be entered)",
      {allow_empty: false, default: ""}) do |data|
      vault.title = data.as String
    end
  end

  def location(vault : Parser::Vault)
    string("Location(e.g. dropbox.com | default: nil)",
      {allow_empty: true, default: ""}) do |data|
      vault.location = data.as String
    end
  end

  def signature(vault : Parser::Vault)
    boolean("Signature(e.g. false | default: true)",
      {allow_empty: true, default: true}) do |data|
      return vault.signature = String.new if false == data.as Bool
      Render.ask_master_key do |master_key|
        builder = Shield::Builder.new Shield::Option.from_json vault.to_json
        secure_id = Shield::Utilit.create_id vault.title
        builder.create_key(master_key, secure_id) do |done?, data|
          if done?
            builder.create_pin! data do |pin|
              hmac = OpenSSL::PKCS5.pbkdf2_hmac secret: data, salt: pin,
                iterations: vault.iterations, algorithm: OpenSSL::Algorithm::SHA512
              vault.signature = hmac.hexstring
            end
          end
        end
      end
    end
  end

  def user_name(vault : Parser::Vault)
    string("UserName(e.g. user | secret)",
      {allow_empty: true, default: ""}) do |data|
      if "secret" == data
        puts "Please Enter The Secret UserName Option.".colorize.yellow
        vault.userName = "[protected]"
        vault.nameEmail.userName.nonce = "Name"
        integer("NameLength(e.g. 15 | default: 20)",
          {allow_empty: true, default: 12,
           min: 3, max: 99}) do |data|
          vault.nameEmail.userName.length = data.as Int32
        end
        integer("Iterations(e.g. 32768 | default: 16384)",
          {allow_empty: true, default: 16384,
           min: 0, max: Int32::MAX}) do |data|
          vault.nameEmail.userName.iterations = data.as Int32
        end
      else
        vault.userName = data.as String
      end
    end
  end

  def email(vault : Parser::Vault)
    string("EmailAddress(e.g. user@example.com | secret)",
      {allow_empty: true, default: ""}) do |data|
      if "secret" == data
        puts "Please Enter The Secret Email Option.".colorize.yellow
        vault.email = "[protected]"
        string("Domain(e.g. example.com | Must be entered)",
          {allow_empty: false, default: ""}) do |data|
          vault.nameEmail.email.domain = data.as String
        end
        integer("NameLength(e.g. 15 | default: 12)",
          {allow_empty: true, default: 12,
           min: 3, max: 99}) do |data|
          vault.nameEmail.email.length = data.as Int32
        end
        integer("Iterations(e.g. 32768 | default: 16384)",
          {allow_empty: true, default: 16384,
           min: 0, max: Int32::MAX}) do |data|
          vault.nameEmail.email.iterations = data.as Int32
        end
      else
        vault.email = data.as String
      end
    end
  end

  def pin_code(vault : Parser::Vault)
    string("PinCode(e.g. 123456 | secret)",
      {allow_empty: true, default: ""}) do |data|
      if "secret" == data
        vault.pinCode = "[protected]"
      else
        vault.pinCode = data.as String
      end
    end
  end

  def use_symbol(vault : Parser::Vault)
    boolean("UseSymbol(e.g. false | default: true)",
      {allow_empty: true, default: true}) do |data|
      vault.useSymbol = data.as Bool
    end
  end

  def iterations(vault : Parser::Vault)
    integer("Iterations(e.g. 262144 | default: 131072)",
      {allow_empty: true, default: 131072,
       min: 0, max: Int32::MAX}) do |data|
      vault.iterations = data.as Int32
    end
  end

  def length(vault : Parser::Vault)
    integer("Length(e.g. 15 | default: 20)",
      {allow_empty: true, default: 20,
       min: 10, max: 99}) do |data|
      vault.length = data.as Int32
    end
  end
end
