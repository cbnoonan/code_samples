class NodeApi::Response::TransfersActivityEnded < NodeApi::Response::Base

  def transfers
    response_parsed['transfers']
  end

  def iteration_token
    response_parsed['iteration_token']
  end

  def schema
    {
      :type => Hash,
      :keys => [
        error_schema[:keys][0],
        {
          "iteration_token" => {
            :type => String
          },
          "transfers" => {
            :type => Array,
            :of => {
              :type => Hash,
              :keys => [
                {
                  "uuid"                 => { :type => String },
                  "start_time"           => { :type => Time },
                  "end_time"             => { :type => Time },
                  "status"               => { :type => String },
                  "error_code"           => { :type => Integer },
                  "error_desc"           => { :type => String },
                  "transport"            => { :type => String },
                  "endpoint"             => { :type => String },
                  "client_node_uuid"     => { :type => String },
                  "server_node_uuid"     => { :type => String },
                  "client_ip_address"    => { :type => String },
                  "server_ip_address"    => { :type => String },
                  "files_expected"       => { :type => Integer },
                  "files_completed"      => { :type => Integer },
                  "files_failed"         => { :type => Integer },
                  "files_skipped"        => { :type => Integer },
                  "files_transferring"   => { :type => Integer },
                  "directories_expected" => { :type => Integer },
                  "bytes_expected"       => { :type => Integer },
                  "bytes_written"        => { :type => Integer },
                  "bytes_transferred"    => { :type => Integer },
                  "rate_policy"          => { :type => String },
                  "target_rate_kbps"     => { :type => Integer },
                  "minimum_rate_kbps"    => { :type => Integer },
                  "calculated_rate_kbps" => { :type => Integer },
                  "elapsed_usec"         => { :type => Integer },
                  "bytes_lost"           => { :type => Integer },
                  "network_delay_usec"   => { :type => Integer },
                  "total_files"          => { :type => Integer },
                  "sessions" => {
                    :type => Array,
                    :of => {
                      :type => Hash,
                      :keys => [
                        {
                          "uuid"              => { :type => String },
                          "start_time"        => { :type => Time },
                          "end_time"          => { :type => Time },
                          "status"            => { :type => String },
                          "error_code"        => { :type => Integer },
                          "error_desc"        => { :type => String },
                          "transport"         => { :type => String },
                          "client_ip_address" => { :type => String },
                          "server_ip_address" => { :type => String },
                        }
                      ]
                    }
                  },
                  "start_spec" => {
                    :type => Hash,
                    :keys => [
                      {
                        "source_paths" => {
                          :type => Array,
                          :of => {
                            :type => Hash,
                            :keys => [
                              "path" => { :type => String },
                              "dest" => { :type => String, :optional => true }
                            ]
                          }
                        },
                        "destination_path"   => { :type => String },
                        "tags"               => {
                          :type => Hash
                        },
                        "token"                => { :type => String },
                        "cookie"               => { :type => String },
                        "direction"            => { :type => String },
                        "remote_host"          => { :type => String },
                        "remote_user"          => { :type => String },
                        "fasp_port"            => { :type => Integer },
                        "ssh_port"             => { :type => Integer },
                        "dgram_size"           => { :type => Integer },
                        "rate_policy"          => { :type => String },
                        "min_rate_kbps"        => { :type => Integer },
                        "target_rate_kbps"     => { :type => Integer },
                        "vlink_id"             => { :type => Integer },
                        "cipher"               => { :type => String },
                        "content_protection"   => { :type => String },
                        "keepalive"            => { :type => Boolean },
                        "http_fallback"        => { :type => Boolean },
                        "http_fallback_port"   => { :type => Integer },
                        "authentication"       => { :type => String },
                        "lock_rate_policy"     => { :type => Boolean },
                        "lock_target_rate"     => { :type => Boolean },
                        "lock_min_rate"        => { :type => Boolean },
                        "target_rate_cap_kbps" => { :type => Integer },
                        "min_rate_cap_kbps"    => { :type => Integer },
                        "policy_allowed"       => { :type => String },
                        "excludes"             => { :type => String },
                        "includes"             => { :type => String }
                      }
                    ]
                  },
                  "files" => {
                    :type => Array,
                    :of => {
                      :type => Hash,
                      :keys => [
                        {
                          "uuid"             => { :type => String },
                          "transfer_uuid"    => { :type => String },
                          "path"             => { :type => String },
                          "start_time_usec"  => { :type => Time },
                          "end_time_usec"    => { :type => Time },
                          "status"           => { :type => String },
                          "error_code"       => { :type => Integer },
                          "error_desc"       => { :type => String },
                          "size"             => { :type => Integer },
                          "type"             => { :type => String },
                          "checksum"         => { :type => String },
                          "checksum_type"    => { :type => String },
                          "start_byte"       => { :type => Integer },
                          "bytes_written"    => { :type => Integer },
                          "bytes_contiguous" => { :type => Integer },
                          "elapsed_usec"     => { :type => Integer }
                        }
                      ]
                    }
                  }
                }
              ]
            }
          }
        }
      ]
    }
  end

end
