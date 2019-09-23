module Shadow::Utils
  def self.input : String
    STDIN.gets.to_s.chomp.rstrip
  end

  def self.ask_rename(path, ask : Symbol, &block)
    loop do
      print Render.reply[:rename][ask]
      input = self.input

      break yield String.build do |io|
        io << File.dirname path
        io << "/"
        io << File.basename input
      end
    end
  end

  def self.ask_move(path, ask : Symbol, &block)
    loop do
      print Render.reply[:move][ask]
      input = self.input
      input = input.gsub /\\ /, " "
      input += "/" unless '/' == input[-1]

      if File.directory? input
        break yield String.build do |io|
          io << input << File.basename path
        end
      end

      puts Render.reply[:invalid][:path]
    end
  end

  def self.ask_bind(ask : Symbol, &block)
    loop do
      print Render.reply[:bind][ask]
      input = self.input

      if File.file? input
        break yield input
      end

      puts Render.reply[:invalid][:file]
    end
  end

  def self.exist?(path, ask : Symbol, &block)
    loop do
      break yield true if File.file? path
      print Render.reply[:exist][ask]
      case self.input
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
      print Render.reply[:conflict][ask]
      case self.input
      when "Y", "y"
        _break = false
        self.delete path do
          _break = true
        end

        break yield true if _break
      when "N", "n" then break
      else
        puts Render.reply[:invalid][:input]
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

  def self.mkdir_p(path : String, full_path? : Bool = true, &block)
    begin
      path = File.dirname path if full_path?
      Dir.mkdir_p path
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
