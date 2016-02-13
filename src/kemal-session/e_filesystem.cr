class Session

  def self.e_filesystem_restore_instance(id) : Session
    path = Session.config.sessions_dir + id + ".json"
    # @TODO check if file actually exists
    return from_json(File.read(path)) as Session
  end

  def e_filesystem_save
    File.write(Session.config.sessions_dir + @id + ".json", to_json)
  end

  def self.e_filesystem_gc
    Dir.foreach(Session.config.sessions_dir) do |f|
      full_path = Session.config.sessions_dir + f
      if File.file? full_path
        age = Time.utc_now - File.stat(full_path).mtime # mtime is always saved in utc
        File.delete full_path if age.total_seconds > Session.config.timeout.total_seconds
      end
    end
  end

end
