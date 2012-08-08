import logging

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from pylons.decorators import *
from tictactoe.lib.base import BaseController, render

log = logging.getLogger(__name__)

RANGE = 3
EMPTY = " "
TIE = "TIE"
human = "X"
computer = "O"

       
class Game(object):

    def __init__(self, board):
        self.board = board

    def _computer_move(self):
        """ Make computer move. """

        # the best positions to have, in order
        BEST_MOVES = [(1,1), (0,0), (2,0), (0,2), (2,2), (1,0), (0,1), (2,1), (1,2)]
        board = self.board[:] # make a copy of the board

        empties = [(x, y) for x in range(RANGE) for y in range(RANGE) if board[x][y] == EMPTY]

        # if the computer can win, make that move
        for row, col in empties:
            board[row][col] = computer 
            if self._check_win(computer, board):
                self.board[row][col] = computer 
                return {'x': row, 'y': col} 
            board[row][col] = EMPTY


        # if human can win, block that move
        for row, col in empties:
            board[row][col] = human
            if self._check_win(human, board):
                self.board[row][col] = computer 
                return {'x': row, 'y': col} 
            board[row][col] = EMPTY

        # otherwise, take one of the best moves
        for row, col in BEST_MOVES:
            if (row, col) in empties:
                self.board[row][col] = computer 
                return {'x': row, 'y': col} 

    def _human_move(self):
        """ Get human move. """
        if request.params:
            x =  int(request.params.getone('x'))
            y =  int(request.params.getone('y'))


            try: 
                validate(x)
                validate(y)
            except AssertionError, e:
                log.error('There was a problem with the request object. Invalid: %s' % e )
                raise  

            while self.board[x][y] == EMPTY:

                # if that spot is empty and no one has won yet...
                # allow that turn to take place
                self.board[x][y] = human 
                human_move = {'x': x, 'y': y} 
                return human_move 

                if self.board[x][y] != EMPTY:
                    return False 


    def _next_turn(self, turn):
        """ Switching to the next player""" 
        turn = human if turn == computer else computer 
        return turn
        
    def _check_win(self, turn, board=None):
        """ Loop through all the winning combinations """ 
        board = board or self.board

        # check for all rows down
        for row in board:
            if row.count(turn) == RANGE:
                return True 

        # check for all rows across 
        for col in range(RANGE):
            for row in board:
                if row[col] != turn:
                    break
            else:
                return True 

        # check for diagonal. i.e.: board[0][0], board[1][1], board[2][2]
        for row in range(RANGE):
            col = row
            if board[row][col] != turn:
                break
        else:
            return True 

        # check for the opposite diagonal. i.e.: board[row][(RANGE-1)-row], etc
        for row in range(RANGE):
            col = (RANGE-1) - row
            if board[row][col] != turn:
                break
        else:
            return True 

        if not any(EMPTY in row for row in board):
            return None 

        return False


    def _congrat_winner(self, the_winner):
        """ Congratulate the winner. """
        
        if the_winner == computer:
            msg = "As I predicted, human. I am triumphant once more. \n" \
                "Proof that computers are superior to humans in all regards. <BR><BR>"

        elif the_winner == human:
            msg = "No, no! It cannot be!  Somehow you tricked me, human. <BR><BR>" \
           "But never again! I, the computer, so swears it!<BR><BR>"

        elif the_winner == TIE:
            msg = "STALEMATE.<BR><BR>\n\n"

        return msg 


def validate(param):
    assert param in range(RANGE)

