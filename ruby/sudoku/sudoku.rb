# Sudoku Rules:
#   Each cell should contain a digit 1-9 such that:
#     * horizontal row contains each digit exactly once
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]
#
#       [_ _ _  _ _ _  _ _ _]
#       [1 2 3  4 5 6  7 8 9]
#       [_ _ _  _ _ _  _ _ _]
#
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]
#     * vertical column contains each digit exactly once
#       [_ _ _  _ 1 _  _ _ _]
#       [_ _ _  _ 2 _  _ _ _]
#       [_ _ _  _ 3 _  _ _ _]
#
#       [_ _ _  _ 4 _  _ _ _]
#       [_ _ _  _ 5 _  _ _ _]
#       [_ _ _  _ 6 _  _ _ _]
#
#       [_ _ _  _ 7 _  _ _ _]
#       [_ _ _  _ 8 _  _ _ _]
#       [_ _ _  _ 9 _  _ _ _]
#     * each 3x3 box contains each digit exactly once
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]
#
#       [_ _ _  1 2 3  _ _ _]
#       [_ _ _  4 5 6  _ _ _]
#       [_ _ _  7 8 9  _ _ _]
#
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]
#       [_ _ _  _ _ _  _ _ _]

class Sudoku

  #
  # @param board [Array]
  #
  def initialize(board)
    @board = board
  end

  #
  # @return [Boolean] true if board is valid
  #
  def solved?
    all_numbers = [1,2,3,4,5,6,7,8,9]

    @board.each_with_index do |row, row_index|
      sorted_rows = row.sort_by(&:to_i)
      ## test each row ##
      if sorted_rows != all_numbers
        return false
      else
        columns = []

        row.each_with_index do |column_value, column_index|
          columns << @board[column_index][row_index]
        end
        sorted_columns = columns.sort_by(&:to_i)

        ## test each column ##
        if sorted_columns != all_numbers
          return false
        end
      end
    end

    r_board_0 = []
    r_board_1 = []
    r_board_2 = []

    m_board_0 = []
    m_board_1 = []
    m_board_2 = []

    l_board_0 = []
    l_board_1 = []
    l_board_2 = []

    @board.each_with_index do |row, row_index|
      row.each_with_index do |column_value, column_index|
        if row_index < 3
          l_board_0 << @board[column_index][row_index] if column_index < 3
          l_board_1 << @board[column_index][row_index] if (3 <= column_index) && (column_index < 6)
          l_board_2 << @board[column_index][row_index] if (6 <= column_index) && (column_index < 9)
        end

        if (3 <= row_index) && (row_index < 6)
          m_board_0 << @board[column_index][row_index] if column_index < 3
          m_board_1 << @board[column_index][row_index] if (3 <= column_index) && (column_index < 6)
          m_board_2 << @board[column_index][row_index] if (6 <= column_index) && (column_index < 9)
        end

        if (6 <= row_index) && (row_index < 9)
          r_board_0  << @board[column_index][row_index] if column_index < 3
          r_board_1  << @board[column_index][row_index] if (3 <= column_index) && (column_index < 6)
          r_board_2  << @board[column_index][row_index] if (6 <= column_index) && (column_index < 9)
        end
      end
    end

    return false unless r_board_0.sort_by(&:to_i) == all_numbers
    return false unless r_board_1.sort_by(&:to_i) == all_numbers
    return false unless r_board_2.sort_by(&:to_i) == all_numbers
    return false unless m_board_0.sort_by(&:to_i) == all_numbers
    return false unless m_board_1.sort_by(&:to_i) == all_numbers
    return false unless m_board_2.sort_by(&:to_i) == all_numbers
    return false unless l_board_0.sort_by(&:to_i) == all_numbers
    return false unless l_board_1.sort_by(&:to_i) == all_numbers
    return false unless l_board_2.sort_by(&:to_i) == all_numbers

    true
  end

  def format(board)
    output = '   '
    (0..8).each do |row|
      (0..8).each do |col|
        if board[row][col].nil?
          output << '_'
        else
          output << board[row][col].to_s
        end
        if col % 3 == 2
          output << '   '
        elsif col != 8
          output << ' '
        end
      end
      output << "\n" if row%3==2
      output << "\n   "
    end
    output << "\n"
    return output
  end
end





class SudokuTest
  class << self

    def failure
      assert Sudoku.new([
        [1,2,3, 4,5,6, 7,8,9],
        [1,2,3, 4,5,6, 7,8,9],
        [1,2,3, 4,5,6, 7,8,9],

        [1,2,3, 4,5,6, 7,8,9],
        [1,2,3, 4,5,6, 7,8,9],
        [1,2,3, 4,5,6, 7,8,9],

        [1,2,3, 4,5,6, 7,8,9],
        [1,2,3, 4,5,6, 7,8,9],
        [1,2,3, 4,5,6, 7,8,9],

      ]).solved?
    end

    def success
      assert Sudoku.new([
        [7,5,6, 4,1,2, 8,3,9],
        [4,9,2, 8,3,5, 1,7,6],
        [8,3,1, 6,7,9, 2,5,4],

        [6,4,9, 1,5,8, 7,2,3],
        [3,1,7, 2,4,6, 5,9,8],
        [2,8,5, 7,9,3, 6,4,1],

        [1,7,8, 3,2,4, 9,6,5],
        [9,2,4, 5,6,1, 3,8,7],
        [5,6,3, 9,8,7, 4,1,2],
      ]).solved?
    end

    protected

      def assert(condition)
        if condition
          puts "works!"
        else
          puts "doesnt work!"

          raise "Assertion failure" unless condition
        end
      end

  end
end


SudokuTest.success
SudokuTest.failure
