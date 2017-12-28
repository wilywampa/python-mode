fun! pymode#breakpoint#init() "{{{

    " If breakpoints are either disabled or already defined do nothing.
    if ! g:pymode_breakpoint || g:pymode_breakpoint_cmd != ''
        return

    " Else go for a 'smart scan' of the defaults.
    else

        PymodePython << EOF

from imp import find_module

for module in ('wdb', 'pudb', 'ipdb'):
    try:
        find_module(module)
        break
    except ImportError:
        continue

EOF
    endif

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
