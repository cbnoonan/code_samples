from tictactoe.tests import *

class TestGameController(TestController):

    def test_index(self):
        response = self.app.get(url(controller='game', action='index'))
        # Test response...
