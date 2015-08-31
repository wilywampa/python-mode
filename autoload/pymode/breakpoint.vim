fun! pymode#breakpoint#init() "{{{

    if !g:pymode_breakpoint
        return
    endif

    if g:pymode_breakpoint_cmd == ''
        let g:pymode_breakpoint_cmd = 'import pdb; pdb.set_trace()  # XXX BREAKPOINT'

        if g:pymode_python == 'disable'
            return
        endif

    endif

        PymodePython << EOF

from imp import find_module

for module in ('wdb', 'pudb', 'ipdb'):
    try:
        find_module(module)
        break
    except ImportError:
        continue

EOF

endfunction "}}}

fun! pymode#breakpoint#operate(lnum) "{{{
    call cursor(a:lnum, 0)
    if search(join(split(g:pymode_breakpoint_cmd, "\r"), '.*\n.*'), 'cn') == a:lnum
        execute "normal ".len(split(g:pymode_breakpoint_cmd, "\r"))."dd"
    else
        let plnum = prevnonblank(a:lnum)
        call append(line('.')-1, map(split(g:pymode_breakpoint_cmd, "\r"),
            \ 'repeat(" ", indent(line("."))) . v:val'))
        normal k
    endif
endfunction "}}}
