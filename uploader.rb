require "net/ftp"
require "yaml"
require "byebug"

class Uploader

  def initialize
    config = YAML.load_file("config.yaml")
    @path = config["path"]
    @uploaded_files = config["uploaded_files"]
    @old = config["old"]
    @address = config["address"]
    @port = config["port"]
    @login = config["login"]
    @password = config["password"]
    @time = config["refresh"]
    @client = Net::FTP.new(@address, @login, @password)
  end

  def overwrite_and_upload()
    @gh_files.each do |file|
      if @up_files.include?(file) && @old_files.include?(file)
        @client.delete("/old/#{file}")
      end
      if @up_files.include?(file)
        @client.rename(file, "/old/#{file}")
      end
      @client.login(@login, @password)
      @gh_files.each do |file|
        @client.putbinaryfile("#{@path}/#{file}", file)
      end
    end
  end

  def splitter(path = "/")
    weird_string_array = @client.dir(path)
    file_names = []
    weird_string_array.each do |line|
      name = line.split(":")[-1][3..-1]
      file_names << name unless name == "old"
    end
    return file_names
  end

  def upload
    while true
      sleep(@time)
      @gh_files = Dir.entries(@path)
      @up_files = splitter()
      @old_files = splitter("/old")
      @gh_files.delete_at(0)
      @gh_files.delete_at(0)
      @gh_files.sort!
      overwrite_and_upload
    end
  end
end
