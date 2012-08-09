module NodeApi
  module FakeUtils

    POLICIES = %w[ fixed high fair low ]

    STATUSES = %w[
      running completed partially_completed failed cancelled willretry orphaned
    ]

    TRANSPORTS = %w[ fasp http ]

    def fake_ip
      [ 10, 0, rand(253) + 1, rand(253) + 1 ].join('.')
    end

  end
end
