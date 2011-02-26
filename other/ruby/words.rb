#!/usr/bin/env ruby
DEBUG=ENV.include?("DEBUG")


# We implement a simplified variant of a Radix tree here.  In particular, we're
# expanding substrings into sub-trees such that all keys in the tree are of
# length 1.  It's naive and not overly memory-efficient, but it's nice and
# simple.
class Tree 

  def initialize
    @root = Hash.new
  end

 # Add a word to the tree.
  def add(word)
    current_node = @root

    # if current_node[ch] is not nil, give it to me otherwise 
    # initialize it to a new hash and give me that.
    word.chars.each { |ch| 
        current_node[ch] = (current_node[ch] or {})
        current_node = current_node[ch]
    }

    current_node[:terminal] = true
  end

  # Determine if a word is a composite of words that appear in the tree.
  def is_composite?(word)
    return remainder(word.chars.to_a)
  end


protected

  # Determine if a word BEGINS with a word in the tree, and return:
  # true: Returned if the word is an exact match for a word in the tree.
  # false: No prefix of the word exists in the tree.
  # Array: The remainder of the word, after the longest in-tree prefix word has
  #        been removed.
  def remainder(word)
    # Accept either a String or a an Array so we don't have to round-trip
    # between the two for multiple iterations, or needlessly complicate the
    # interface...

    current_node = @root

    # word is an array, use of shift will return the first element
    while (ch = word.shift) # TODO: Use of shift is probably inefficient.
      tmp = current_node[ch]
      if (tmp.nil?)
        if (current_node.include?(:terminal))
          # There exists a word in the tree which is a prefix of our parameter.
          return remainder(word.unshift(ch)) # TODO: unshift is probably inefficient.
        else
          # There does NOT exist a word in the tree which is a prefix of our
          # parameter.
          return false
        end
      else
        current_node = tmp
      end
    end
   if current_node.include?(:terminal)
      # This exact word is present...
      return true
    else
      # Our parameter is a prefix of a word in the tree, but our parameter does
      # not appear in the tree itself.  In this case, that means our word ends
      # with something that isn't itself a word in the tree.
      return false
    end
  end
end

# Start with a reading in the words file 
#
# Then, sort by word-length, shortest first. This allows us to safely determine
# our longest composite word as we build the tree.

start = Time.new
f = File.open("words.txt") or die "Unable to open file..."
#f = File.open("test.txt") or die "Unable to open file..."

sortedList =  f.readlines.map { |word| 
                                word.chomp
                              }.sort_by{ |x| x.length}

puts "Loaded #{sortedList.count} words..." 

puts "Calculating..."

tree = Tree.new
longestWordSoFar = ''

sortedList.each do |word|
  printf ">> #{word}" if(DEBUG)

  if (tree.is_composite?(word))
    if (word.length > longestWordSoFar.length)
      printf "!" if(DEBUG)
      longestWordSoFar = word
    elsif(word.length == longestWordSoFar.length)
      # For consistency, among equal-length words, choose the one that comes 
      # earliest alphabetically.
      if(word < longestWordSoFar)
        printf "*" if(DEBUG)
        longestWordSoFar = word
      end
    else
      printf "~" if(DEBUG)
    end
  else
    printf "+" if(DEBUG)
    tree.add(word)
  end
  puts "" if(DEBUG)
end

puts "THIS IS THE LONGEST WORD!:"
puts longestWordSoFar 

stop = Time.new
total = stop.to_f - start.to_f
puts "Total time: #{total}"
