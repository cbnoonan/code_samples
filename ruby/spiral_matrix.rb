# Given a 2D array (matrix) named M, print all items of M in a spiral order, clockwise.
# For example:

# M  =  [
#        [1,2,3,4,5],
#        [6,7,8,9,10],
#        [11,12,13,14,15],
#        [16,17,18,19,20]
#        ]

# The clockwise spiral print is:  1 2 3 4 5 10 15 20 19 18 17 16 11 6 7 8 9 14 13 12


# topRow = 0
# bottomRow = m - 1
# leftCol = 0
# rightCol = n - 1


# Let M be a matrix of m rows and n columns.
def spiral_matrix_print(matrix)
    m = 0
    n = 0

	matrix.each_with_index do |row, r_i|
	  n = row.length
	  columns = []
	  row.each_with_index do |c, c_i|
        columns << matrix[c_i][r_i] unless matrix[c_i].nil?
	  end
	  m = columns.length
    end
	topRow = 0
	bottomRow = m - 1
	leftCol = 0
	rightCol = n - 1

	while topRow <= bottomRow && leftCol <= rightCol
	  # print the next top row
	    (leftCol..rightCol).each do |i|
          puts matrix[topRow][i]
	    end
	    topRow += 1

        # print the next right hand side column
        (topRow..bottomRow).each do |i|
          puts matrix[i][rightCol]
        end
        rightCol -= 1

        # print the bottom row
        if topRow <= bottomRow
          rightCol.downto(leftCol) do |i|
            puts matrix[bottomRow][i]
          end
          bottomRow -= 1
        end

        # print the next left hand side column
        if leftCol <= rightCol
        	bottomRow.downto(topRow) do |i|
               puts matrix[i][leftCol]
            end
            leftCol += 1
        end

	end

end


spiral_matrix_print([
       [1,2,3,4,5],
       [6,7,8,9,10],
       [11,12,13,14,15],
       [16,17,18,19,20]])