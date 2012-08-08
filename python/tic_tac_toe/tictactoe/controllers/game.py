import logging

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from pylons.decorators import *
from tictactoe.lib.base import BaseController, render
from tictactoe.lib.game import Game 

log = logging.getLogger(__name__)

RANGE = 3
EMPTY = " "
TIE = "TIE"
human = "X"
computer = "O"

       
class GameController(BaseController):

    def __init__(self):
        if not 'board' in session:
            self.board = [
                [EMPTY, EMPTY, EMPTY],
                [EMPTY, EMPTY, EMPTY],
                [EMPTY, EMPTY, EMPTY],
                ]
        else:
            self.board = session['board']

    def index(self):
        return render('/game.html')


    @jsonify
    def main(self):
        human_move = msg  = None
        computer_move = ''
        turn = human
        g = Game(self.board)

        while not g._check_win(turn):
            if turn == human:
                try:
                    human_move = g._human_move()

                    session['board'] = self.board
                    session.save()

                    if not human_move:
                        return {'errmsg':  "That square is already occupied, foolish human. Choose another."} 
                except AssertionError, e:
                        return {'errmsg':  "Index out of range. Choose another."} 
            else:
                computer_move = g._computer_move()

                session['board'] = self.board
                session.save()

            if g._check_win(turn) or g._check_win(turn) == None:
                if g._check_win(turn) == None:
                    msg = g._congrat_winner(TIE)
                else:
                    msg = g._congrat_winner(turn)

                if session.has_key('board'):
                    del session['board']

                return {'computerMove': computer_move, 'humanMove': human_move, 'msg': msg }
            else: 
                turn = g._next_turn(turn)


            # for all regular moves 
            if computer_move and human_move:
               return {'computerMove': computer_move, 'humanMove': human_move, 'msg': msg  }


def validate(param):
    assert param in range(RANGE)

