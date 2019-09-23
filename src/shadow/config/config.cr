module Shadow::Config
  def self.default_path
    String.build do |io|
      io << ENV["HOME"] << "/.shadow.yml"
    end
  end

  def self.init_config
    Utils.conflict? default_path, :conflict do |conflict?|
      Render.delete default_path if conflict?
      config = Parser::Config.new
      Shadow::Parser::Config.default config
      Utils.write default_path, config.to_yaml do
        Render.create default_path
        yield
      end
    end
  end

  def self.parse_config(path = default_path)
    begin
      Utils.read path do |text|
        yield Parser::Config.from_yaml text
      end
    rescue ex : YAML::Error
      raise ParseFailed.new ex.message
    end
  end

  def self.default_path_exist?
    Utils.exist? default_path, :config do |exist?|
      yield exist?
    end
  end

  def self.load_config
    default_path_exist? do |exist?|
      if exist?
        parse_config do |config|
          return yield config
        end
      end

      init_config do
        default_path_exist? do |exist?|
          if exist?
            parse_config do |config|
              yield config
            end
          end
        end
      end
    end
  end

  def self.destroy
    destroy_database do
      Utils.delete default_path do
        Render.destroy default_path
      end
    end
  end

  def self.move_database
    load_config do |config|
      Utils.ask_move config.database, :database do |after|
        Utils.move config.database, after do
          before = config.database
          config.database = after
          Utils.write default_path, config.to_yaml do
            Render.move before, after
          end
        end
      end
    end
  end

  def self.rename_database
    load_config do |config|
      Utils.ask_rename config.database, :database do |after|
        Utils.rename config.database, after do
          before = config.database
          config.database = after
          Utils.write default_path, config.to_yaml do
            Render.rename before, after
          end
        end
      end
    end
  end

  def self.bind_database
    load_config do |config|
      Utils.ask_bind :database do |after|
        before = config.database
        config.database = after
        Utils.write default_path, config.to_yaml do
          Render.bind before, after
        end
      end
    end
  end

  def self.reset_database
    load_config do |config|
      Utils.conflict? config.database, :database do |conflict?|
        Render.delete config.database if conflict?
        default = Parser::Config.new
        Shadow::Parser::Config.default default
        Utils.write config.database, String.new do
          Render.reset config.database
        end
      end
    end
  end

  def self.destroy_database(&block)
    load_config do |config|
      Utils.delete config.database do
        Render.delete config.database
        yield true
      end
    end
  end

  def self.init_database
    load_config do |config|
      Utils.conflict? config.database, :database do |conflict?|
        Render.delete config.database if conflict?
        default = Parser::Config.new
        Shadow::Parser::Config.default default
        Utils.mkdir_p default.database do
          Utils.create default.database do
            config.database = default.database
            Utils.write default_path, config.to_yaml do
              Render.create default.database
            end
          end
        end
      end
    end
  end
end
