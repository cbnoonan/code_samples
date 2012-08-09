module AppTar
  class AtDir < Base
    attr_accessor :dir
    
    def initialize(dir)
      self.dir = dir
    end
    
    def save
      FileUtils.mkdir_p(save_dest_path)
      FileUtils.cp_r(save_source_path, save_dest_path)
      log "copied: #{save_source_path} to #{save_dest_path}"
      erase_svn_files
    end
    
    # Erase .svn files that were copied to #save_dest_path.  Should only be 
    # necessary on development machines with Console checked out rather
    # than exported.
    def erase_svn_files
      Dir["#{save_dest_path}/**/.svn"].each do |file|
        puts "erasing target: #{file}"
        FileUtils.remove_entry(file)
      end
    end
      
    def save_source_path
      "#{dir}/."
    end
    
    def save_dest_path
      "#{save_dir}/#{dir}"
    end

    def restore
      log "copied: #{restore_source_path} to #{restore_dest_path}"
      FileUtils.cp_r(restore_source_path, restore_dest_path)
    end
    
    def restore_source_path
      "#{restore_dir}/#{dir}/."
    end
    
    def restore_dest_path
      dir
    end
    
  end
end