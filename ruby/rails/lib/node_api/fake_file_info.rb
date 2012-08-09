module NodeApi
  class FakeFileInfo

    include FakeUtils

    def initialize(i)
      @i       = i
    end

    def result
      {}
        .merge(summary)
        .merge(stats)
    end

    private

    def summary
      {
        :uuid            => SecureRandom.uuid,
        :transfer_uuid   => SecureRandom.uuid,
        :path            => "file#{@i}",
        :start_time_usec => 2.days.ago,
        :end_time_usec   => 1.day.ago,
        :status          => STATUSES.sample,
        :error_code      => 1,
        :error_desc      => 'text',
        :size            => 100 + @i,
        :type            => %w[ directory file symlink ].sample,
        :checksum        => 'text',
        :checksum_type   => %w[ md5 sha1 md5_sparse sha1_sparse ].sample,
        :start_byte      => 10,
      }
    end

    def stats
      {
        :bytes_written    => 100,
        :bytes_contiguous => 100,
        :elapsed_usec     => 100,
      }
    end

  end
end
