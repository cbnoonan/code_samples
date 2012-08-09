module NodeApi
  class TransfersActivityEnded < Base

    def transfers_activity_ended
      path = request_parsed['path']
      options = {
        :max_files_per_transfer => request_parsed['max_files_per_transfer']
      }
      @result = FakeTransfersActivityEnded.new(path, options).result
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

  end
end
