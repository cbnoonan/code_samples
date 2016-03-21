#As a user I can enter a phrase "hello" and see it translated to Pig Latin "ellohay"
#As a user I can enter a phrase "hello world" and see it translated to Pig Latin "ellohay orldway"
#As a user I can enter a phrase "Hello world" and see it translated to Pig Latin "Ellohay orldway"
#As a user I can enter a phrase "Hello, world!!" and see it translated to "Ellohay, orldway!!"
#As a user I can enter a phrase "eat apples" and see it translated to Pig Latin "eatay applesay"
#As a user I can enter a phrase "quick brown fox" and see it translated to Pig Latin "ickquay ownbray oxfay"


def pig_latin_translate(string)

  tokens = string.split(' ')
  pig_latin_string = []

  tokens.each do |str|
  	lowercase_str = str.downcase
	  len = lowercase_str.length


    if lowercase_str.match(/^[a|e|i|o|u]/)
	    lowercase_str =  "#{lowercase_str}ay"
	  elsif m = lowercase_str.match(/(^[qu|br]+)/)
	    lowercase_str =  "#{lowercase_str[2..len]}#{m[0]}ay"
    else
	    lowercase_str =  "#{lowercase_str[1..len]}#{lowercase_str[0]}ay"
	  end
	  lowercase_str.capitalize! if str.capitalize == str


    if m = lowercase_str.match(/([[:punct:]]+)/)
    	lowercase_str.tr!(m[0],'')
    	lowercase_str = "#{lowercase_str}#{m[0]}"
    end

    pig_latin_string << lowercase_str
  end

  pig_latin_string.join(' ')
end



require "test/unit"
include Test::Unit::Assertions



class TestPigLatin < Test::Unit::TestCase

  def test_simple
    assert_equal("ellohay", pig_latin_translate("hello"))
    assert_equal("ellohay orldway", pig_latin_translate("hello world"))
    assert_equal("Ellohay orldway", pig_latin_translate("Hello world") )
    assert_equal("Ellohay, orldway!!", pig_latin_translate("Hello, world!!") )
    assert_equal("eatay applesay", pig_latin_translate("eat apples"))
    assert_equal("ickquay ownbray oxfay", pig_latin_translate("quick brown fox"))
  end
end