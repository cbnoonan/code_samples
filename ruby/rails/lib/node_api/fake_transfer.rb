module NodeApi
  class FakeTransfer

    include FakeUtils

    def initialize(path, options)
      @path           = path
      @total_files    = rand(50)
      @reported_files = [
        @total_files,
        options[:max_files_per_transfer] || 10
      ].min
      @endpoint = %w[ client server ].sample
      @direction = %w[ send receive ].sample
    end

    def result
      {}
        .merge(transfer_info)
        .merge({
           :files       => @reported_files.times.map { |i| FakeFileInfo.new(i).result },
           :total_files => @total_files
         })
    end

    private

    def transfer_info
      {}
        .merge(transfer_summary)
        .merge(transfer_start_spec_info)
        .merge(transfer_stats)
    end

    def transfer_summary
      # Notes: transfer-level fields take the value of the last session if
      # different between sessions (for example server_ip_address can be
      # different if the server use DNS round-robin, or :error_code” when all
      # sessions in the retry sequence failed
      {
        :uuid              => SecureRandom.uuid,
        :start_time        => rand(2.hours).ago,
        :end_time          => Time.zone.now,
        :status            => STATUSES[1],
        :error_code        => rand(3),
        :error_desc        => 'desc',
        :transport         => TRANSPORTS.sample,
        :endpoint          => @endpoint,
        :client_node_uuid  => SecureRandom.uuid,
        :server_node_uuid  => SecureRandom.uuid,
        :client_ip_address => fake_ip,
        :server_ip_address => fake_ip,
        :sessions          => (1 + rand(2)).times.map do
          {
            :uuid              => SecureRandom.uuid,
            :start_time        => rand(2.hours).ago,
            :end_time          => Time.zone.now,
            :status            => STATUSES.sample,
            :error_code        => 1,
            :error_desc        => 'desc',
            :transport         => TRANSPORTS.sample,
            :client_ip_address => fake_ip,
            :server_ip_address => fake_ip
          }
        end
      }
    end

    def transfer_start_spec_info
      {
        :start_spec => {
          :source_paths         => (1 + rand(3)).times.map { |i| source_path(i) },
          :destination_path     => destination_path,
          :tags                 => { :name1 => :value1, :name2 => :value2 },
          :token                => 'text',
          :cookie               => 'text',
          :direction            => @direction,
          :remote_host          => 'text',
          :remote_user          => 'text',
          :fasp_port            => 33001,
          :ssh_port             => 22,
          :dgram_size           => 100,
          :rate_policy          => POLICIES.sample,
          :target_rate_kbps     => 1_000_000,
          :min_rate_kbps        => 1_000,
          :vlink_id             => 100,
          :cipher               => %w[ aes128 none ].sample,
          :content_protection   => %w[ encrypt decrypt ].sample,
          :keepalive            => [ true, false ].sample,
          :http_fallback        => [ true, false ].sample,
          :http_fallback_port   => 100,
          :authentication       => %w[ password key token ].sample,
          :lock_rate_policy     => [ true, false ].sample,
          :lock_target_rate     => [ true, false ].sample,
          :lock_min_rate        => [ true, false ].sample,
          :target_rate_cap_kbps => 100,
          :min_rate_cap_kbps    => 100,
          :policy_allowed       => POLICIES.sample,
          :excludes             => 'and i can exclude this',
          :includes             => 'and i can include that',
        }
      }
    end

    def inbound?
      # the connection initiator is the client endpoint
      # direction is from the viewpoint of the client.
      #   ie, is the client sending or receiving.
      #   if querying both sides about a single transfer, both will
      #     report 'sending' or both will report 'receiving'

      # files are inbound if
      # * the remote connected to me (I am the server) and the client (the remote) sent files
      # or
      # * I connected to the remote (I am the client) and the client (me) received files
      @endpoint == 'server' && @direction == 'send' || @endpoint == 'client' && @direction == 'receive'
    end

    # a source_path is a hash { :path => "", :dest => "" }, where :dest is optional.
    # if :dest exists,
    # * the source file is renamed in flight, possibly to a different directory.
    # * the destination directory is relative to transfer_start_spec_black:start_spec:destination_path
    def source_path(i)
      if inbound?
        path = "/remote/dir/source_#{i}"
        if [ true, false ].sample
          { :path => path }
        else
          dest = "/local/dir/renamed_source_#{i}"
          { :path => path, :dest => dest }
        end
      else
        path = File.join(@path, "local/dir/source_#{i}")
        if [ true, false ].sample
          { :path => path }
        else
          dest = "/remote/dir/renamed_source_#{i}"
          { :path => path, :dest => dest }
        end
      end
    end

    def destination_path
      if inbound?
        File.join(@path, "/local/dir/destination")
      else
        "/remote/dir/destination"
      end
    end

    def transfer_stats
      {
        :files_expected       => @total_files,
        :files_completed      => @total_files,
        :files_failed         => 0,
        :files_skipped        => 0,
        :files_transferring   => 0,
        :directories_expected => 0,
        :bytes_expected       => 100,
        :bytes_written        => 100,
        :bytes_transferred    => 100,
        :rate_policy          => POLICIES.sample,
        :target_rate_kbps     => 100,
        :minimum_rate_kbps    => 100,
        :calculated_rate_kbps => 768_000,
        :elapsed_usec         => 100,
        :bytes_lost           => 100,
        :network_delay_usec   => 100
      }
    end

  end
end
