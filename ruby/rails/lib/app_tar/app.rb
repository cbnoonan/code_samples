require 'open3'

module AppTar
  class App < Base

    Aspera::Process::WHITELIST << 'tar' unless Aspera::Process::WHITELIST.include?('tar')
    Aspera::Process::WHITELIST << "#{Console.mysql_bin_dir}/mysql" unless Aspera::Process::WHITELIST.include?("#{Console.mysql_bin_dir}/mysql")
    Aspera::Process::WHITELIST << "#{Console.mysql_bin_dir}/mysqldump" unless Aspera::Process::WHITELIST.include?("#{Console.mysql_bin_dir}/mysqldump")
   
    def save
      save_initialize_dir
      save_items
      save_tar_items
      true
    rescue Exception => e
      logger.error "#{e.class} #{$!}\n#{$!.backtrace.join("\n")}"
      self.error_message = "Error saving configuration.  See log for details."
      false
    end

    def save_initialize_dir
      log "save directory: #{save_dir}"
      if File.directory?(save_dir)
        delete =  `sudo #{RAILS_ROOT}/delete_backup_dir.sh #{save_dir} 2>&1` 
        raise("Error cleaning up old backup directories\n#{delete}\n")  if $? != 0
      end
      FileUtils.mkdir_p(save_dir)
    end
    
    def save_items
      items.each do |item|
        item.save
      end
    end
    
    def save_tar_items
      log "tarring up all files with: #{tar_cmd_args.join(' ')}"
      FileUtils.cd(save_dir) do
        tar = Aspera::Process.new_process( tar_cmd_args, :err => :out )
        tar.run
        raise("Error tarring config\n#{tar.exitstatus}\n#{tar.stdout}") unless tar.exitstatus.zero?
      end
    end

    def tar_cmd_args
      ['tar', '-cvzf', save_path, '.']
    end

    def save_path
      "#{save_restore_dir}/save-console.tar.gz"
    end
    
    def save_download_filename
      "console_#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}.tar.gz"
    end
    
    def restore(uploaded_or_os_file)
      restore_initialize_dir
      if restore_write_file(uploaded_or_os_file)
        restore_untar_items
        restore_items
        true
      end
    rescue Exception => e
      logger.error "#{e.class} #{$!}\n#{$!.backtrace.join("\n")}"
      self.error_message = "Error restoring configuration.  See log for details."
      false
    end
    
    def restore_initialize_dir
      log "restore directory: #{restore_dir}"
      FileUtils.rm_r(restore_dir) if File.directory?(restore_dir)
      FileUtils.mkdir_p(restore_dir)
    end
    
    def restore_write_file(uploaded_or_os_file)
      if uploaded_or_os_file.instance_of?(String)
        restore_write_os_file(uploaded_or_os_file)
        true
      else
        restore_write_uploaded_file(uploaded_or_os_file)
      end
    end
    
    def restore_write_os_file(os_file)
      log "restore write os file. copying: #{os_file} to #{restore_path}"
      FileUtils.cp(os_file, restore_path)     
    end
    
    def restore_write_uploaded_file(uploaded_file)
      if uploaded_file.blank?
        self.error_message = 'Upload a saved configuration'
        false
      else
        File.open(restore_path, "w") { |f| f.print(uploaded_file.read) }
        true
      end
    end
    
    def restore_untar_items
      log "restore untar items. #{restore_path}" 
      FileUtils.cd(restore_dir) do
        untar = Aspera::Process.new_process( untar_cmd_args, :err => :out )
        untar.run     
        raise "Error untarring config\n#{untar.exitstatus}\n#{untar.stdout}" unless untar.exitstatus.zero?
      end
    end
    
    def untar_cmd_args
      ['tar', '-xvzf', restore_path]
    end

    def restore_path
      "#{save_restore_dir}/restore-console.tar.gz"
    end
    
    def restore_items
      items.each do |item|
        item.restore
      end
    end
 
    def items
      [
        items_os_files,
        items_database,
        items_shares,
        items_dirs_rails, 
      ].flatten
    end
    
    def items_os_files 
      AppTar::AtDirOsFiles.new
    end
    
    def items_shares 
      AppTar::Shares.new
    end
    
    def items_database      
      AppTar::MysqlDatabase.new( :tables => items_database_tables )
    end
    
    def items_database_tables
      AsperaRails::Database.all_tables
    end
    
    def items_dirs_rails
      dirs = %w(
        app/views/notifier/templates
        config
        public/images/maps
      )
      
      dirs.map do |rails_dir|
        AppTar::AtDir.new("#{rails_dir}")      
      end
    end
    
  end
end
