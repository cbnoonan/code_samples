module NodeApi
  class Transfer < Base

    attr_reader :result

    class TokenGenerationError < StandardError; end

    def upload
      transfer_specs(:upload)
    end

    def download
      transfer_specs(:download)
    end

    private

    def transfer_specs(direction)
      transfer_specs = []
      request_parsed = JSON.parse(request.raw_post)
      unless request_parsed.has_key?('transfer_requests')
        @result = {
          :error => {
            :user_message => 'Invalid request: missing "transfer_requests" property'
          }
        }
        return @result
      end
      request_parsed['transfer_requests'].each do |req_container|
        begin
          next unless req_container.has_key?('transfer_request')
          transfer_request = req_container.delete('transfer_request')

          transfer_specs << {
            :transfer_spec => transfer_spec(direction, transfer_request),
          }.merge(req_container)
          
        rescue TokenGenerationError
          transfer_specs << {
            :error => {
              :user_message => 'Token generation error',
              :internal_message => "#{$!.class.name}: #{$!.message}"
            }
          }
        rescue
          transfer_specs << {
            :error => {
              :internal_message => "#{$!.class.name}: #{$!.message}"
            }
          }
        end
      end
      @result = {
        :transfer_specs => transfer_specs
      }      
    end

    def transfer_spec(direction, transfer_request)
      if direction == :upload
        upload_transfer_spec(transfer_request)
      else
        download_transfer_spec(transfer_request)
      end.merge({
        :remote_host          => request.host,
        :remote_user          => 'asp1',
        :ssh_port             => 22,
        :fasp_port            => 33001,
      })
    end

    def upload_transfer_spec(transfer_request)
      destinations = transfer_request["paths"].map { |path| File.join('/', transfer_request['destination_root'] || '', path['destination'] || '') }
      {}.tap do |transfer_spec|
        transfer_spec[:destination_root] = transfer_request['destination_root'] if transfer_request['destination_root']
        transfer_spec[:source_root]      = transfer_request['source_root'] if transfer_request['source_root']
        transfer_spec[:paths]            = transfer_request['paths']
        transfer_spec[:token]            = upload_token(destinations)
        transfer_spec[:direction]        = 'send'
        transfer_spec[:cookie]           = transfer_request['cookie'] if transfer_request['cookie']
        transfer_spec[:tags]             = transfer_request['tags'] if transfer_request['tags']
      end
    end

    def download_transfer_spec(transfer_request)
      sources = transfer_request["paths"].map { |path| File.join('/', transfer_request['source_root'] || '', path['source'] || '') }
      {}.tap do |transfer_spec|
        transfer_spec[:destination_root] = transfer_request['destination_root'] if transfer_request['destination_root']
        transfer_spec[:source_root]      = transfer_request['source_root'] if transfer_request['source_root']
        transfer_spec[:paths]            = transfer_request['paths']
        transfer_spec[:token]            = download_token(sources)
        transfer_spec[:direction]        = 'receive'
        transfer_spec[:cookie]           = transfer_request['cookie'] if transfer_request['cookie']
        transfer_spec[:tags]             = transfer_request['tags'] if transfer_request['tags']
      end
    end

    def upload_token(destinations)
      begin
        astokengen = %W[ #{astokengen_path} -u asp1 ]
        astokengen += destinations.map { |destination| %W[ -p #{destination} ] }.flatten
        Open3.popen3(*astokengen) { |stdin, stdout| stdout.readline.chomp }
      rescue
        raise TokenGenerationError, "#{$!.class.name} #{$!.message}"
      end
    end

    def download_token(sources)
      begin
        astokengen = %W[ #{astokengen_path} -u asp1 -d ]
        astokengen += sources.map { |source| %W[ -p #{source} ] }.flatten
        Open3.popen3(*astokengen) { |stdin, stdout| stdout.readline.chomp }
      rescue
        raise TokenGenerationError, "#{$!.class.name} #{$!.message}"
      end
    end

    def astokengen_path
      File.exist?('/opt/aspera/bin/astokengen') ? '/opt/aspera/bin/astokengen' : '/Library/Aspera/bin/astokengen'
    end

  end
end
