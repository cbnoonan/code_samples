require_relative 'card'

class Deck

	def initialize(include_jokers = false)
		@cards_used = 0
		cards_created = 0
		@cards = []

		(0..3).each do |s|
			(1..13).each do |v|
				@cards[cards_created] = Card.new(v, s)
				cards_created = cards_created + 1
			end
		end

		if include_jokers
			@cards[52] =  Card.new(1, Card::JOKER)
			@cards[53] =  Card.new(2, Card::JOKER)
		end
	end


    def shuffle
    	@cards_used = 0

    	# @deck.shuffle
    	(@cards.length-1).downto(1) do |c|
    		random = rand * (c+1)
    		temp = @cards[c]  # temp holds the value of the 51st card
    		@cards[c] = @cards[random]
    		@cards[random] = temp
    	end
    end

    def deal_card
    	if @cards_used == @cards.size
    		raise Exception
    	end
    	@cards_used += 1
    	@cards[@cards_used - 1]
    end

    def cards_left
    	@cards.length - @cards_used
    end

    def has_jokers?
    	@cards.size == 54
    end


end


# deck = Deck.new  #without includeJokers
# puts deck.shuffle
# puts deck.deal_card
# puts deck.has_jokers?

# deck_with_jokers = Deck.new(true)
# puts deck_with_jokers.shuffle
# puts deck_with_jokers.deal_card
# puts deck_with_jokers.has_jokers?