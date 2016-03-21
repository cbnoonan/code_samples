#
# An object of type Hand represents a hand of cards.  The
# cards belong to the class Card.  A hand is empty when it
# is created, and any number of cards can be added to it.
#
require_relative 'card'
require_relative 'deck'


class Hand

  def initialize
  	@cards = []
  end

  def clear
  	@cards.clear
  end

  # Add a card to the hand.  It is added at the end of the current hand.
  def add_card(card)
  	@cards << card
  end

  def remove_card(card)
  	@cards.delete(card)
  end

  def remove_card_at(position)
  	if position < 0 || position >= @cards.size
  		raise Exception "Position does not exist in hand: #{position}"
  	end
  	@cards.delete_at(position)
  	@cards
  end

  def card_count
  	@cards.size
  end

  def cards
    @cards
  end

  # get card in the specified position in the hand.
  def card(index)
  	if index < 0 || index >= @cards.size
  	  raise Exception "Position does not exist in hand: #{index}"
  	end
  	@cards[index]
  end


  # Sorts the cards in the hand so that cards of the same suit are
  # grouped together, and within a suit the cards are sorted by value.
  # Note that aces are considered to have the lowest value, 1.
  def sort_by_suit
  	new_hand = []
    while @cards.size > 0
    	pos = 0  # position of minimal card
    	c = @cards[0] # minimal card
    	@cards.each_with_index do |card, index|
    		c1 = card
        # puts "c: #{c.inspect} and c1: #{c1.inspect}"
        # puts " and c1.suit: #{c1.suit}"
    		if (c1.suit < c.suit || (c1.suit == c.suit && c1.value < c.value) )
    			pos = index
    			c = c1
    	  end
    	end

    	remove_card_at(pos)
    	new_hand << c
    end

    @cards = new_hand
  end

  # Sorts the cards in the hand so that cards of the same value are
  # grouped together.  Cards with the same value are sorted by suit.
  # Note that aces are considered to have the lowest value, 1.
  def sort_by_value
  	new_hand = []
  	while @cards.size > 0
  		pos = 0
  		c = @cards[0]
  		@cards.each_with_index do |card, index|
  			c1 = card
  			if (c1.value < c.value || (c1.suit == c.suit && c1.suit < c.suit) )
          pos = index
          c = c1
        end
      end

      remove_card_at(pos)
      new_hand << c
    end
    @cards = new_hand

  end
end

deck = Deck.new
deck.shuffle
# puts "deck: #{deck.inspect}"

hand = Hand.new
hand.add_card(deck.deal_card)
hand.add_card(deck.deal_card)
hand.add_card(deck.deal_card)
hand.add_card(deck.deal_card)
hand.add_card(deck.deal_card)
hand.add_card(deck.deal_card)
hand.add_card(deck.deal_card)
hand.add_card(deck.deal_card)

hand.sort_by_suit
hand.sort_by_value
card = hand.cards.sample(1)
# puts hand.remove_card(card)
# puts "foo: #{hand.card(3).inspect}"
# puts "carD: #{card.inspect}"

hand.clear


