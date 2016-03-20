require_relative 'card'

class Deck

	def initialize(include_jokers = false)
		@cards_used = 0
		cards_created = 0
		@deck = []

		(0..3).each do |s|
			(1..13).each do |v|
				@deck[cards_created] = Card.new(v, s)
				cards_created = cards_created + 1
			end
		end

		if include_jokers
			@deck[52] =  Card.new(1, Card::JOKER)
			@deck[53] =  Card.new(2, Card::JOKER)
		end
	end


    def shuffle
    	@cards_used = 0

    	# @deck.shuffle
    	(@deck.length-1).downto(1) do |c|
    		foo = rand
    		random = foo * (c+1)
    		temp = @deck[c]  # temp holds the value of the 51st card
    		@deck[c] = @deck[random]
    		@deck[random] = temp
    	end
    end

    def deal_card
    	if @cards_used == @deck.size
    		raise Exception
    	end
    	@cards_used += @cards_used
    	@deck[@cards_used - 1]
    end

    def cards_left
    	@deck.length - @cards_used
    end

    def has_jokers?
    	@deck.size == 54
    end


end


deck = Deck.new  #without includeJokers
puts deck.shuffle
puts deck.deal_card
puts deck.has_jokers?

deck_with_jokers = Deck.new(true)
puts deck_with_jokers.shuffle
puts deck_with_jokers.deal_card
puts deck_with_jokers.has_jokers?