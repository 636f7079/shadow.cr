module Shadow::Utilit
  extend self

  def reply : NamedTuple
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

  def input : String
    STDIN.gets.to_s.chomp.rstrip
  end

  def ask_rename(dir, ask : Symbol)
    loop do
      print reply[:rename][ask]
      input = Utilit.input
      input += "/" unless '/' == input[-1]
      break yield File.dirname(dir) + input
    end
  end

  def ask_move(dir, ask : Symbol)
    loop do
      print reply[:move][ask]
      if File.directory? input = Utilit.input
        input += "/" unless '/' == input[-1]
        break yield input + File.basename(dir)
      end
      puts reply[:invalid][:path]
    end
  end

  def ask_bind(ask : Symbol)
    loop do
      print reply[:bind][ask]
      input = Utilit.input
      if File.file? input
        break yield input
      end
      puts reply[:invalid][:file]
    end
  end

  def exist?(path, ask : Symbol)
    loop do
      break yield true if File.file? path
      print reply[:exist][ask]
      case Utilit.input
      when "Y", "y" then break yield false
      when "N", "n" then abort nil
      end
    end
  end

  def conflict?(path : String, ask : Symbol)
    loop do
      unless File.file? path
        break yield false
      end
      print reply[:conflict][ask]
      case Utilit.input
      when "Y", "y"
        self.delete path do
          break yield true
        end
      when "N", "n" then break
      else
        puts reply[:invalid][:input]
      end
    end
  end

  def rename(before, after : String)
    begin
      yield if File.rename before, after
    rescue ex : Errno
      raise RenameFailed.new ex.message
    end
  end

  def move(before, after : String)
    begin
      yield if FileUtils.mv before, after
    rescue ex : Errno
      raise MoveFailed.new ex.message
    end
  end

  def create(path : String)
    begin
      yield if FileUtils.touch path
    rescue ex : Exception
      raise CreateFailed.new ex.message
    end
  end

  def read(path : String)
    begin
      yield File.read path
    rescue ex : Errno
      raise ReadFailed.new ex.message
    end
  end

  def delete(path : String)
    begin
      yield if File.delete path
    rescue ex : Errno
      raise DeleteFailed.new ex.message
    end
  end

  def mkdir_p(path : String)
    begin
      yield if Dir.mkdir_p File.dirname(path)
    rescue ex : Errno
      raise CreateFailed.new ex.message
    end
  end

  def write(path, text : String)
    begin
      yield if File.write path, text, mode: "wb"
    rescue ex : Errno
      raise WriteFailed.new ex.message
    end
  end
end
