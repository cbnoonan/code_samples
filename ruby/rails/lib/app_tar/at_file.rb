module AppTar
  class AtFile < Base
    attr_accessor :paths
    
    def initialize(paths)
      self.paths = paths.instance_of?(Array) ? paths : [paths]
    end
    
    def save
      paths.each do |path|
        dest_dir = destination_dir(path)
        FileUtils.mkdir_p(dest_dir)
        FileUtils.cp(path, dest_dir)
      end
    end
    
    def destination_dir(path)
      "#{save_dir}/#{File.dirname(path)}"
    end
    
    def restore
      paths.each do |path|
        source_dir = "#{restore_dir}"
        FileUtils.cp "#{source_dir}/#{path}", path
      end
    end
    
  end
end