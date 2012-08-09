module AppTar
  class Base
    attr_accessor :error_message
    
    def save_restore_dir
      # Rails.root + "/data/app_tar"
      RAILS_ROOT + "/data/app_tar"
    end
    
    def save_dir
      "#{save_restore_dir}/save"
    end
     
    def restore_dir
      "#{save_restore_dir}/restore"
    end
    
    def log(s)
      puts s
    end
    
    def os_user_class
      self.class.os_user_class
    end

    def os_file_class
      self.class.os_file_class
    end
    
    def logger
      self.class.logger
    end
    
    class << self
      def os_user_class
        Ami::Base.os_user_class
      end
      
      def os_file_class
        Ami::Base.os_file_class
      end
      
      def logger
        RAILS_DEFAULT_LOGGER
      end
      
    end
  end
end