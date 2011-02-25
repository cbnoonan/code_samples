
$tryWordList ={} 
class MyClass

  def readFileAndSort() 
     f = File.open("words.txt") or die "Unable to open file..."

     contentsArray=[]  # start with an empty array
     f.each_line {|line|
         contentsArray.push line
     }

     sortedList =  contentsArray.sort_by{|x| x.length}.reverse

     puts "Calculating..."

     getLongestWord(sortedList)
  end

  # find longest word and return it
  def getLongestWord(words)
    puts "size:  #{words.length}"
    longestSoFar = ''

    for i in 0..(words.length-1)
        tryCount = 0
        longestSoFar = words[i].chomp

        for j in i+1..(words.length-1)
            # iterate through every word in the list, setting original value to testWord
            # then find if other strings (words in the file) occur
#            puts "i: #{i} j: #{j} testword #{words[i].chomp} value j: #{words[j].chomp!} longestSoFar: #{longestSoFar}"

            if longestSoFar.include? words[j]
#               puts "AWESOME. words[j] is in longestSoFar"
               $tryWordList[tryCount+=1] = words[j]
            end
         end
#         puts "trywordlist " 
#         p $tryWordList
         longestSoFar = remove_leader(longestSoFar, $tryWordList, tryCount)
         if longestSoFar == nil
            puts "winner ${words[i]}"
            stop = Time.new
            totalTime = stop.to_f - start.to_f 
            puts "total time : #{totalTime}"
            return EXIT_SUCCESS
         end
    end
    return EXIT_FAILURE
  end

  def remove_leader(longestSoFar, candidates, tryCount)
    puts "longest so far: #{longestSoFar}"
    puts "try count : #{tryCount}"
    puts "candidates : "
    p candidates
#    puts "tryWordList kys: #{$tryWordList.keys}"
#    puts "tryWordList: #{$tryWordList}"
    longest = longestSoFar
    if longestSoFar.length == 0
        return nil
    end 
#    for i in 0..(tryCount-1) 
    for i in 1..tryCount 
#       puts "length of i word #{$tryWordList[i].length}"
       len = $tryWordList[i].length 
       puts "longesSoFar length #{longestSoFar[0..len]}"
       puts "tryword list #{$tryWordList[i][0..len]}"
       if (longestSoFar[0..len] <=> $tryWordList[i][0..len]) == 0  
          puts "lengths are equal"
          longest = remove_leader(longestSoFar + len, candidates, tryCount)
          if longest == nil
             return longest
          end
       else
          puts "lengths are not equal"
       end
    end
    return longest
  end
  

end

start = Time.new

c = MyClass.new()
c.readFileAndSort

