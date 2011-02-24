

class MyClass
  def readFileAndSort() 
     f = File.open("words.txt") or die "Unable to open file..."

     contentsArray=[]  # start with an empty array
     f.each_line {|line|
         contentsArray.push line
     }

     sortedList =  contentsArray.sort_by{|x| x.length}.reverse

#     puts sortedList.inspect

     puts "Calculating..."

     getLongestWord(sortedList)
  end

  # find longest word and return it
  def getLongestWord(words)
    puts "size:  #{words.length}"
    word = ''
    testWord = ''
    validWord = ''
    candidates = []
    permutation = ''


    catch (:done) do
        for i in 0..words.length
            word = words[i].chomp!
            testWord = word
#            puts "1: testword:  #{testWord}"

            for j in i+1..words.length
            # iterate through every word in the list, setting original value to testWord
            # then find if other strings (words in the file) occur
                puts "1. testword #{testWord} value j: #{words[j]}"
                testWord = testWord.gsub(words[j].chomp!,'') 
                puts "2: testword:  #{testWord}"

                if testWord.length == 1
                    #  too short, replace original word and carry on
                    testWord = word
                end
                if testWord.length == 0
                   validWord = word
#                   isValidWord dd= True
                    throw :done  
#                   break
                 end
            end
        end
    end
    puts "valid word: #{validWord}"
#   MethodFactory methodFactory = new MethodFactory(intMethod);
#        String strValidWord = methodFactory.objMethod.getLongestWord(lstWords);
 
#        return strValidWord;
  end

end


c = MyClass.new()
c.readFileAndSort

