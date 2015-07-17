"""Check for calls on uncallable objects."""
import tokenize
from tokenize import NUMBER, OP, STRING
try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

from .. import Linter as BaseLinter


TEMPLATE = 'attempt to call uncallable object (%s)'
OBJS = {
    NUMBER: 'number literal',
    STRING: 'string literal',
    OP: 'dict/set comprehension',
}


class Linter(BaseLinter):

    """Illegal call checker."""

    @staticmethod
    def run(path, code=None, **meta):
        readline = StringIO(code).readline
        prev = None
        errors = []
        for item in tokenize.generate_tokens(readline):
            ttype, tstr, (lnum, col), _, _ = item
            if (prev and ttype == tokenize.OP and tstr == '(' and
                    (prev[0] in [NUMBER, STRING] or
                     (prev[0] == OP and prev[1] == '}'))):
                errors.append(dict(
                    lnum=lnum,
                    col=col,
                    text=TEMPLATE % OBJS[prev[0]],
                    type='E',
                ))
            prev = item
        return errors
