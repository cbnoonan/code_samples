#
# An object of type Card represents a playing card from a
# standard Poker deck, including Jokers.  The card has a suit, which
# can be spades, hearts, diamonds, clubs, or joker.  A spade, heart,
# diamond, or club has one of the 13 values: ace, 2, 3, 4, 5, 6, 7,
# 8, 9, 10, jack, queen, or king.  Note that "ace" is considered to be
# the smallest value.  A joker can also have an associated value;
# this value can be anything and can be used to keep track of several
# different jokers.
#
class Card
	SPADES = 0
	HEARTS = 1
	DIAMONDS = 2
	CLUBS = 3
	JOKER = 4

	ACE = 1
	JACK = 11
	QUEEN = 12
	KING = 13

    def initialize(value, suit)
    	if ((suit != SPADES) && (suit != HEARTS) && (suit != DIAMONDS) && (suit != CLUBS) && (suit != JOKER))
            raise Exception.new ("IllegalArgumentException: s: #{suit} and v: #{value}")
        end
    	if (suit != JOKER && (value < 1 || value > 13))
            raise Exception.new ("IllegalArgumentException")
    	end
    	@value = value
    	@suit = suit
    end

    def value
        @value
    end

    def suit
        @suit
    end

    def get_suit_as_string
    	case @suit
	    	when SPADES
	    		"Spades"
	    	when HEARTS
	    		"Hearts"
	    	when DIAMONDS
	    		"Diamonds"
	    	when CLUBS
	    		"Clubs"
	    	else
	    		"Joker"
	    end
    end

    def get_value_as_string
    	if @suit == JOKER
    		return "" + @value
    	else
    		case @value
    			when 1
    				return "Ace"
    			when 2
    				return "2"
    			when 3
    				return "3"
    			when 4
    				return "4"
    			when 5
    				return "5"
    			when 6
    				return "6"
    			when 7
    				return "7"
    			when 8
    				return "8"
    			when 9
    				return "9"
    			when 10
    				return "10"
    			when 11
    				return "Jack"
    			when 12
    				return "Queen"
    			else
    				return "King"
    		end
    	end
    end

    def to_string
    	if @suit == JOKER
    		if @value == 1
    			"JOKER"
    		else
    			"JOKER #{@value}"
    		end
    	else
    		"#{get_value_as_string} of #{get_suit_as_string}"
    	end
    end


end

# card = Card.new(11, 3)
# puts card.to_string
# puts card.suit
# puts card.value