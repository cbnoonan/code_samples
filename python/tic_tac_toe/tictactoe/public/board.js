/* Drawing a board */
var TicTacToe = {
    board: ["", "", "", "", "", "", "", "", "", ""],
    win: false,
    turn: "0",

    drawBoard: function() {
        var board_table = '<table class="board" border="0px" cellpadding="0px" cellspacing="0px" align="center"><tr><td id="0_0">&nbsp;</td><td id="1_0">&nbsp;</td><td id="2_0">&nbsp;</td></tr><tr><td id="0_1">&nbsp;</td><td id="1_1">&nbsp;</td><td id="2_1">&nbsp;</td></tr><tr><td id="0_2">&nbsp;</td><td id="1_2">&nbsp;</td><td id="2_2">&nbsp;</td></tr></table>';
         $("#board").html(board_table);
         $("#menu").hide();

         // clear the board
         this.board = ["", "", "", "", "", "", "", "", "", ""];

         // Add on-click events to each of the boxes of the board
         $("#board td").click(function(e) {
            TicTacToe.move( this.cellIndex, this.parentNode.rowIndex); 
         });
    },

    /** make a global for the main page render (game/move)  **/
    move: function(x, y) {

      jQuery.ajax({
        type:'POST',
        url: '/game/main',
        dataType:'json',
        data: "x="+x+"&y="+y,
        success: function(data){
            TicTacToe.onSuccess(data);
        },
        error:function (xhr, ajaxOptions, thrownError){
          alert(xhr.status);
        }
      });
    },

    onSuccess: function(data) {
          if (data.errmsg) {
              alert('Problem!: ' + data.errmsg);
          } else {
              $("#" + data.humanMove.x + "_" + data.humanMove.y).html('X');
              $("#" + data.computerMove.x + "_" + data.computerMove.y).html('O');

              if (data.msg) {
                  TicTacToe.endGame(data.msg);
              }
          }
    },

    endGame: function(msg) {

      $("#menu").html(msg);
      $("#menu").append("<div id='play_again'>Want to Play Again?</div>");
 
      // Button for playing again.
      $("#play_again").click(function () { TicTacToe.drawBoard();  });
      $("#menu").show();
      this.win = false;
    }
}
