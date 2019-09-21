module Shadow::Config
  extend self

  def default_path
    ENV["HOME"] + "/.shadow.yml"
  end

  def init_config
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

  def parse_config(path = default_path)
    begin
      Utils.read path do |text|
        yield Parser::Config.from_yaml text
      end
    rescue ex : YAML::Error
      raise ParseFailed.new ex.message
    end
  end

  def path_exist?
    Utils.exist? default_path, :config do |exist?|
      yield exist?
    end
  end

  def load_config
    path_exist? do |exist?|
      parse_config do |config|
        return yield config
      end if exist?
      init_config do
        path_exist? do |exist?|
          parse_config do |config|
            yield config
          end if exist?
        end
      end
    end
  end

  def destroy
    destroy_database do
      Utils.delete default_path do
        Render.destroy default_path
      end
    end
  end

  def move_database
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

  def rename_database
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

  def bind_database
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

  def reset_database
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

  def destroy_database
    load_config do |config|
      Utils.delete config.database do
        Render.delete config.database
        yield true
      end
    end
  end

  def init_database
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
