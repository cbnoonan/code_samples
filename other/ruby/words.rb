f = File.open("words.txt") or die "Unable to open file..."

contentsArray=[]  # start with an empty array
f.each_line {|line|
    contentsArray.push line
}

#puts contentsArray.inspect

sorted_list =  contentsArray.sort_by{|x| x.length}

puts sorted_list.inspect

