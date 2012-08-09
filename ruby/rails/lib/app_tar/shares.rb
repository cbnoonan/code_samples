module AppTar
  class Shares < Base
    
    def save
      log "executing shares backup"
      shares_save_dir = "#{save_dir}/#{dir}"
      FileUtils.rm_r(shares_save_dir) if File.directory?(shares_save_dir)
      FileUtils.mkdir_p(shares_save_dir)
      shares_backup =  `sudo #{RAILS_ROOT}/script/shares.sh #{shares_save_dir} 2>&1`
      raise("Error saving shares\n#{shares_backup}\n")  if $? != 0
    end
    
    def restore
      log "executing shares restore"
      shares_restore =  `sudo #{RAILS_ROOT}/script/restore_shares.sh  #{shares_restore_path} 2>&1`
      raise("Error restoring shares\n#{shares_restore}\n")  if $? != 0
    end
    
    def dir
      "shares"
    end
    
    def shares_restore_dir
      "#{restore_dir}/#{dir}"
    end
    
    def shares_restore_path
      Dir.glob("#{shares_restore_dir}/*").first
    end
    
  end
end