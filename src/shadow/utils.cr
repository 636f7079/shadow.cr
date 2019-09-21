module Shadow::Utils
  def self.reply : NamedTuple
    {
      exist: {
        config: "Can't find the configuration file, initialize? (Y/n) ",
      },
      conflict: {
        config:   "The Configuration File already exists, delete? (Y/n) ",
        database: "The Database File already exists, delete? (Y/n) ",
      },
      move: {
        database: "Move the DataBase File to: ",
      },
      bind: {
        database: "Bind the DataBase File to: ",
      },
      rename: {
        database: "Rename the DataBase File to: ",
      },
      invalid: {
        path:  "Invalid Path, Please try again.",
        file:  "Invalid File, Please try again.",
        input: "Invalid Input, Please try again.",
      },
    }
  end

  def self.input : String
    STDIN.gets.to_s.chomp.rstrip
  end

  def self.ask_rename(dir, ask : Symbol, &block)
    loop do
      print reply[:rename][ask]
      i = input
      i += "/" unless '/' == i[-1]
      input = i.gsub /\\ /, " "
      break yield File.dirname(dir) + input
    end
  end

  def self.ask_move(dir, ask : Symbol, &block)
    loop do
      print reply[:move][ask]
      i = input
      i += "/" unless '/' == i[-1]
      input = i.gsub /\\ /, " "
      if File.directory? input
        break yield input + File.basename(dir)
      end
      puts reply[:invalid][:path]
    end
  end

  def self.ask_bind(ask : Symbol, &block)
    loop do
      print reply[:bind][ask]
      input = self.input
      if File.file? input
        break yield input
      end
      puts reply[:invalid][:file]
    end
  end

  def self.exist?(path, ask : Symbol, &block)
    loop do
      break yield true if File.file? path
      print reply[:exist][ask]
      case input
      when "Y", "y" then break yield false
      when "N", "n" then abort nil
      end
    end
  end

  def self.conflict?(path : String, ask : Symbol, &block)
    loop do
      unless File.file? path
        break yield false
      end
      print reply[:conflict][ask]
      case input
      when "Y", "y"
        _break = false
        self.delete path do
          _break = true
        end

        break yield true if _break
      when "N", "n" then break
      else
        puts reply[:invalid][:input]
      end
    end
  end

  def self.rename(before, after : String, &block)
    begin
      File.rename before, after
      yield
    rescue ex : Errno
      raise RenameFailed.new ex.message
    end
  end

  def self.move(before, after : String, &block)
    begin
      FileUtils.mv before, after
      yield
    rescue ex : Errno
      raise MoveFailed.new ex.message
    end
  end

  def self.create(path : String, &block)
    begin
      FileUtils.touch path
      yield
    rescue ex : Exception
      raise CreateFailed.new ex.message
    end
  end

  def self.read(path : String, &block)
    begin
      yield File.read path
    rescue ex : Errno
      raise ReadFailed.new ex.message
    end
  end

  def self.delete(path : String, &block)
    begin
      File.delete path
      yield
    rescue ex : Errno
      raise DeleteFailed.new ex.message
    end
  end

  def self.mkdir_p(path : String, &block)
    begin
      Dir.mkdir_p File.dirname(path)
      yield
    rescue ex : Errno
      raise CreateFailed.new ex.message
    end
  end

  def self.write(path, text : String, &block)
    begin
      File.write path, text, mode: "wb"
      yield
    rescue ex : Errno
      raise WriteFailed.new ex.message
    end
  end
end
