module NodeApi
  class FakeTransfersActivityEnded

    def initialize(path, options)
      @path    = path
      @options = options
    end

    def result
      {
        :iteration_token => rand(10_000).to_s,
        :transfers       => 2.times.map { FakeTransfer.new(@path, @options).result }
      }
    end

  end
end
