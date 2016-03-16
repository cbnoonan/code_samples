class Deck


	def initialize(includeJokers = false)

		@cardsUsed = 0
		cardsCreated = 0
		@deck = []

		suits = ['Heart', 'Spade', 'Diamond', 'Club']

		suits.each do |suit|
			[1..13].each do |i|
				@deck[cardsCreated] = Card(i, suit)
				cardsCreated++
			end
		end

		if includeJokers
			@deck[52] =  Card(1, Card.Joker);
			@deck[53] =  Card[2, Card.Joker];
		end
	end


    def shuffle
    	@deck.shuffle
    end

    def dealCard
    	if @cardsUsed == @deck.size
    		raise Exception
    	end
    	@cardsUsed++
    	@deck[@cardsUsed - 1]
    end

    def cardsLeft
    	@deck.length - @cardsUsed
    end


end