module NodeApi
  class TransfersFiles < Base

    def files
      @request_parsed = JSON.parse(request.raw_post)
      @path = @request_parsed['path']
      @result = {
        :files => [
          fake_file,
          fake_file
        ],
        :iteration_token => rand(10_000).to_s
      }
      true
    rescue
      Rails.logger.error "#{$!.class} (#{$!.message})\n  #{$!.backtrace.join "\n  "}"
      @error = {:code => 1000, :user_message => 'There was a problem...'}
      false
    end

    def result
      @result
    end

    def error
      @error
    end

  private

    def fake_file
      {
        :id => SecureRandom.uuid,
        :server_ip => fake_ip,
        :server_ssh_port => 22,
        :client_ip => fake_ip,
        :target_rate => 1_000_000,
        :average_rate => 768_000,
        :source_path => File.join(!upload ? @path : '', 'sources', 'source' + rand(100).to_s),
        :destination_path => File.join(upload ? @path : '', 'destinations', 'destination' + rand(100).to_s),
        :files_count => 2,
        :files_complete => 2,
        :files_failed => 0,
        :files_summary_list => [{:path => 'file1', :size => 1}, {:path => 'file10', :size => 1}],
        :bytes_transferred => 1,
        :bytes_lost => 1,
        :usec_elapsed => 100_000,
        :datetime_start => '2011-10-01 01:02:03',
        :datetime_end => '2011-10-01 02:03:04',
        :session_ids => [ 1010, 2020 ],
        :error_code => 1,
        :error_description => ''
      }
    end

  end
end
