require 'find'

module NodeApi
  class FileSystemOperations < Base

    attr_accessor :files, :path

    class InvalidPathError < RuntimeError; end

    def browse
      @request_parsed = JSON.parse(request.raw_post)
      fullpath = "#{path}/*"
      select_files_items_and_sort(fullpath)
      true
    # TODO: add exceptions to logfile
    # perhaps have an api call to get errors for admin
    rescue InvalidPathError => e
      self.error = {:code => 3000, :user_message => 'Invalid path or filename'}
      false
    rescue => e
      Rails.logger.error "#{e.class} (#{e.message})\n  #{e.backtrace.join "\n  "}"
      self.error = {:code => 1000, :user_message => 'There was a problem...'}
      false
    end

    def search
      @request_parsed = JSON.parse(request.raw_post)
      fullpath = "#{path}/**/*"
      select_files_items_and_sort(fullpath)
      true
    rescue InvalidPathError => e
      self.error = {:code => 3000, :user_message => 'Invalid path or filename'}
      false
    rescue => e
      Rails.logger.error "#{e.class} (#{e.message})\n  #{e.backtrace.join "\n  "}"
      self.error = {:code => 1000, :user_message => 'There was a problem...'}
      false
    end

    def result
      {
        :items => files[skip, count],
        :total_count => files.length,
        :parameters => @request_parsed
      }
    end

  private
  
    def basename_regexps
      # TODO: clean up this code
      @basename_regexps ||= begin
        if filter.basenames 
          filter.basenames.map do |filter|
            # Dir.glob case sensitivity is system dependent, so we use regexps
            if filter.blank?
              Regexp.new(".")
            else
              glob = Regexp.escape(filter).gsub('\*', '.*').gsub('\?', '.')
              glob = '^' + glob + '$'
              Regexp.new(glob, case_sensitive? ? 0 : Regexp::IGNORECASE)
            end
          end
        else
          []
        end
      end
    end
    
    def select_files_items_and_sort(fullpath)
      result = Dir[fullpath]
      result = result.select do |path|
        basename = File.basename(path)
        basename_regexps.all? { |regexp| basename =~ regexp }
      end unless basename_regexps.empty?

      self.files = result.map do |path|
        stat = File.stat(path)
        DirectoryItem::Base.new_item({
          "path" => File.join(?/, Pathname.new(path).relative_path_from(Pathname.new docroot).to_s),
          "type" => stat.ftype,
          "size" => stat.size,
          "mtime" => stat.mtime.utc,
        })
      end

      self.files = files.delete_if do |f|
        (filter.size_min && (filter.size_min >= f.size)) ||
        (filter.size_max && (filter.size_max <= f.size)) ||
        (filter.mtime_min && (filter.mtime_min >= f.mtime)) ||
        (filter.mtime_max && (filter.mtime_max <= f.mtime))
      end

      case sort
      when 'path' then files.sort! { |a, b| a.path.casecmp(b.path) }
      when 'type' then files.sort! { |a, b| result = a.type <=> b.type; result != 0 ? result : a.path.casecmp(b.path) }
      when 'size_a' then files.sort! { |a, b| result = a.size <=> b.size; result != 0 ? result : a.path.casecmp(b.path) }
      when 'size_d' then files.sort! { |a, b| result = b.size <=> a.size; result != 0 ? result : a.path.casecmp(b.path) }
      when 'mtime_a' then files.sort! { |a, b| result = a.mtime <=> b.mtime; result != 0 ? result : a.path.casecmp(b.path) }
      when 'mtime_d' then files.sort! { |a, b| result = b.mtime <=> a.mtime; result != 0 ? result : a.path.casecmp(b.path) }
      end
    end

    def links
      [self_link, prev_link, next_link].compact
    end

    def assemble_link
      link = "#{location}?path=#{path}&per_page=#{per_page}"

      additional_parameters = ''
      #if params['file_filter']
      #  additional_parameters += "&file_filter=#{filter}"
      #end
      if params['sort']
        additional_parameters += "&sort=#{sort}"
      end
      if params['direction']
        additional_parameters += "&direction=#{direction}"
      end
      if case_sensitive?
        additional_parameters += "&case_sensitive=true"
      end

      link += additional_parameters
    end

    def self_link
      {:rel => 'self', :href => "#{assemble_link}&page=#{results_per_page.current_page}"}
    end

    def next_link
      if results_per_page.next_page && params[:path]
        {
          :rel => 'next',
          :href => "#{assemble_link}&page=#{results_per_page.next_page}"
        }
      end
    end

    def prev_link
      if results_per_page.previous_page && params[:path]
        {
         :rel => 'previous',
         :href => "#{assemble_link}&page=#{results_per_page.previous_page}"
        }
      end
    end

    def location
      request.protocol + request.host_with_port + request.path
    end

    def results_per_page
      files.paginate(:per_page => per_page, :page => params[:page], :page_links => false)
    end

    def case_sensitive?
      @request_parsed['case_sensitive'] || false
    end
    
    def path_valid?(p)
      p.present? && !path_contains_dotdot?(p) && (File.exists?(p) || Dir.exists?(p))
    end
    
    def docroot
      @docroot ||= begin
        if Rails.application.config.respond_to? :docroot
          Rails.application.config.docroot
        else
          Pathname.new '/'
        end
      end
    end

    def path
      @path ||= begin
        path = File.join(docroot, @request_parsed['path'])
        raise InvalidPathError unless path_valid?(path)
        path
      end
    end

    def per_page
      pp = params[:per_page].to_i
      pp = [pp, 10].min
      pp = [pp, 100].max
    end

    def filter
      @filter ||= Node::BrowseFilter.new(@request_parsed['filters'] || {})
    end

    def sort
      @sort ||= @request_parsed['sort']
    end

    def direction
      @request_parsed['direction'] ||= 'a'
    end

    def skip
      (@request_parsed['skip'] || 0).to_i
    end

    def count
      (@request_parsed['count'] || 100).to_i
    end

  end

end
