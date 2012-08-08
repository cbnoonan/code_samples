# -*- encoding:utf-8 -*-
from mako import runtime, filters, cache
UNDEFINED = runtime.UNDEFINED
__M_dict_builtin = dict
__M_locals_builtin = locals
_magic_number = 5
_modified_time = 1290498869.7052691
_template_filename='/home/cbnoonan/src/python/job/tictactoe/templates/game.html'
_template_uri='/game.html'
_template_cache=cache.Cache(__name__, _modified_time)
_source_encoding='utf-8'
from webhelpers.html import escape
_exports = []


def _mako_get_namespace(context, name):
    try:
        return context.namespaces[(__name__, name)]
    except KeyError:
        _mako_generate_namespaces(context)
        return context.namespaces[(__name__, name)]
def _mako_generate_namespaces(context):
    # SOURCE LINE 1
    ns = runtime.Namespace(u'login', context._clean_inheritance_tokens(), templateuri=u'login.html', callables=None, calling_uri=_template_uri, module=None)
    context.namespaces[(__name__, u'login')] = ns

def render_body(context,**pageargs):
    context.caller_stack._push_frame()
    try:
        __M_locals = __M_dict_builtin(pageargs=pageargs)
        __M_writer = context.writer()
        __M_writer(u'\n<html>\n<head>\n  <link href="board.css" rel="stylesheet" type="text/css">\n  <script type="text/javascript" src="jquery.js"></script>\n  <script type="text/javascript" src="board.js"></script>\n  <script type="text/javascript">\n$(document).ready(function() {\n     TicTacToe.drawBoard();\n});\n</script>\n\n   <title>Tic Tac Toe</title>\n</head>\n<body>\n   <h1>Greetings</h1>\n\n<table border="0px" align="center">\n<tr><td>\n<div id="menu"></div>\n<div id="board"></div>\n</td></tr>\n</table>\n\n<a href="tictactoe.tgz">Download Source</a>\n</body>\n</html>\n')
        return ''
    finally:
        context.caller_stack._pop_frame()


