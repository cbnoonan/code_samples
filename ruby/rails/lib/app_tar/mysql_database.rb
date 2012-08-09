module AppTar
  class MysqlDatabase < Base

    attr_accessor :tables
    attr_accessor :db_config

    delegate :database, :username, :password, :host, :port, :to => :db_config

    def initialize(options = {}) 
      self.tables = options[:tables]
    end
    
    def db_config
      @db_config ||= Console
    end
    
    # Save data in #tables.
    def save
      log 'saving mysql ... tables:'
      log tables.join("\n")
      save_insert_file
      save_delete_file
    end
    
    # Writes file of insert statements for #tables
    def save_insert_file
      run_sql_cmd(save_insert_cmd)
    end
    
    # Writes file of delete statements for #tables.
    def save_delete_file
      deletes = tables.map { |table| "delete from #{table};" }
      
      File.open("#{save_dir}/#{delete_filename}", "w") do |file|
        file.print(deletes.join("\n"))
      end
    end
    
    # Returns mysqldump command to export table contents.
    def save_insert_cmd
      cmd_ary = credentials('mysqldump', '--no-create-info', '--complete-insert',
        "--result-file=#{save_dir}/#{insert_filename}")
      cmd_ary += tables
    end  
    
    # Restores data in tables to that in saved files.
    def restore
      log "restoring mysql db"
      restore_delete
      restore_insert
    end
    
    def restore_delete
      run_sql_cmd(restore_delete_cmd)
    end
    
    def restore_insert
      run_sql_cmd(restore_insert_cmd)
    end
    
    # Returns mysql command to delete rows in #tables.
    def restore_delete_cmd
      cmd_ary = credentials('mysql')
      cmd_ary += ["-e", "source #{restore_dir}/#{delete_filename}"]
    end
    
    # Returns mysql command to insert saved rows into #tables.
    def restore_insert_cmd
      cmd_ary =  credentials('mysql')
      cmd_ary += ["-e", "source #{restore_dir}/#{insert_filename}"]
    end
    
    # Builds part of string for executing mysql cmd _executable_.  Any _swithches_
    # appear between the password switch and the database parameter.
    def credentials(executable, *switches)
      cmd_ary = [
        mysql_full_path(executable),
        "--host=#{host}",
        "--port=#{port}",
        "--user=#{username}",
      ]
      cmd_ary << "--password=#{password}"  unless password.to_s.strip == ''
      cmd_ary << switches
      cmd_ary << database
      cmd_ary.flatten
    end
    
    def mysql_full_path(exe)
      "#{Console.mysql_bin_dir}/#{exe}"
    end
    
    # Returns the basename of the file holding sql inserts.   
    def insert_filename
      'insert.sql'
    end
    
    # Returns the basename of the file holding sql deletes.   
    def delete_filename
      'delete.sql'
    end
    
    def run_sql_cmd(args)
      sql = Aspera::Process.new_process(args, :err => :out)
      sql.run
      filtered_cmd = Ami::Base.filter_password(args.join(' '))
      raise("Error running sql\n#{filtered_cmd}\nrc=#{sql.exitstatus}\n#{sql.stdout}") unless sql.success?
    end

  end
end
