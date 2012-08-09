module AppTar
  class AtDirOsFiles < Base
    
    def save
      os_files_dir = "#{save_dir}/#{dir}"
      FileUtils.mkdir_p(os_files_dir)
      Ami::Base.os_file_class.before_save(os_files_dir)
    end
    
    def restore
      os_files_dir = "#{restore_dir}/#{dir}"
      log "restore to #{os_files_dir}"
      Ami::Base.os_file_class.after_restore(os_files_dir)
    end
    
    def dir
      "os_files"
    end
    
  end
end