" PEP8 compatible Python indent file
" Language:         Python
" Maintainer:       Hynek Schlawack <hs@ox.cx>
" Prev Maintainer:  Eric Mc Sween <em@tomcom.de> (address invalid)
" Original Author:  David Bustos <bustos@caltech.edu> (address invalid)
" Last Change:      2012-06-21
" License:          Public Domain


function! pymode#indent#get_indent(lnum)

    " First line has indent 0
    if a:lnum == 1
        return 0
    endif

    let control_structure = '^\s*\(\(el\)\?if\|while\|for\s.*\sin\|except\)\s*'

    " If we can find an open parenthesis/bracket/brace, line up with it.
    call cursor(a:lnum, 1)
    let parlnum = s:SearchParensPair()
    if parlnum > 0
        let parcol = col('.')
        let closing_paren = match(getline(a:lnum), '^\s*[])}]') != -1
        if match(getline(parlnum), '[([{]\s*$', parcol - 1) != -1
            if closing_paren
                return indent(parlnum)
            else
                return indent(parlnum) + &shiftwidth
            endif
        else
            if indent(a:lnum + 1) == parcol &&
                \ match(getline(parlnum), control_structure) != -1
                return parcol + &sw
            else
                return parcol
            endif
        endif
    endif

    " Examine this line
    let thisline = getline(a:lnum)
    let thisindent = indent(a:lnum)

    " If the line starts with 'elif' or 'else', line up with 'if' or 'elif'
    if thisline =~ '^\s*\(elif\|else\)\>'
        let bslnum = s:BlockStarter(a:lnum, '^\s*\(if\|elif\)\>')
        if bslnum > 0
            return indent(bslnum)
        else
            return -1
        endif
    endif

    " If the line starts with 'except' or 'finally', line up with 'try'
    " or 'except'
    if thisline =~ '^\s*\(except\|finally\)\>'
        let bslnum = s:BlockStarter(a:lnum, '^\s*\(try\|except\)\>')
        if bslnum > 0
            return indent(bslnum)
        else
            return -1
        endif
    endif

    " Examine previous line
    let plnum = a:lnum - 1
    let pline = getline(plnum)
    let sslnum = s:StatementStart(plnum)

    " If the previous line is blank, keep the same indentation. If the current
    " line is also blank, this is probably a new line in insert mode, so use
    " the indent of the previous non-blank line's block start, unless the
    " block start is a def/class that hasn't returned yet, then use the
    " class/def indent plus one shiftwidth
    if pline =~ '^\s*$'
        if getline(a:lnum) =~ '^\s*$'
            let start = s:BlockStarter(prevnonblank(a:lnum),
                \ '\v^\s*(class|def|elif|else|except|finally|for|if|try|while|with)>')
            let start = max([start, searchpos('^\S', 'bcnW')])
            if getline(start) =~ '\v^\s*(def|class)>' &&
                \ searchpos('^\s*\(break\|continue\|raise\|return\|pass\)\>', 'bnW')[0] < start
                return indent(start) + &shiftwidth
            elseif getline(a:lnum - 2) =~ '^\s*$'
                return indent(start) - &shiftwidth
            else
                return indent(start)
            endif
        else
            return -1
        endif
    endif

    " If this line is explicitly joined, find the first indentation that is a
    " multiple of four and will distinguish itself from next logical line.
    if pline =~ '\\$'
        let maybe_indent = indent(sslnum) + &sw
        if match(getline(sslnum), control_structure) != -1
            " add extra indent to avoid E125
            return maybe_indent + &sw
        else
            " control structure not found
            return maybe_indent
        endif
    endif

    " If the previous line ended with a colon and is not a comment, indent
    " relative to statement start.
    if pline =~ '^[^#]*:\s*\(#.*\)\?$'
        return indent(sslnum) + &sw
    endif

    " If the previous line was a stop-execution statement or a pass
    if getline(sslnum) =~# '^\s*\(break\|continue\|raise\|return\|pass\)\>'
        \ && synIDattr(synID(sslnum, match(getline(sslnum),
        \ '\(break\|continue\|raise\|return\|pass\)') + 1, 0), "name") !~ 'docstring'
        " See if the user has already dedented
        if indent(a:lnum) > indent(sslnum) - &sw
            " If not, recommend one dedent
            return indent(sslnum) - &sw
        endif
        " Otherwise, trust the user
        return -1
    endif

    " If the line is blank, line up with the start of the previous statement.
    if thisline =~ '^\s*$'
        return indent(sslnum)
    endif

    " In all other cases, trust the user.
    return indent(a:lnum)
endfunction


" Find backwards the closest open parenthesis/bracket/brace.
function! s:SearchParensPair() " {{{
    let line = line('.')
    let col = col('.')

    " Skip strings and comments and don't look too far
    let skip = "line('.') < " . (line - 50) . " ? dummy :" .
                \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? ' .
                \ '"string\\|comment"'

    " Search for parentheses
    call cursor(line, col)
    let parlnum = searchpair('(', '', ')', 'bW', skip)
    let parcol = col('.')

    " Search for brackets
    call cursor(line, col)
    let par2lnum = searchpair('\[', '', '\]', 'bW', skip)
    let par2col = col('.')

    " Search for braces
    call cursor(line, col)
    let par3lnum = searchpair('{', '', '}', 'bW', skip)
    let par3col = col('.')

    " Get the closest match
    if par2lnum > parlnum || (par2lnum == parlnum && par2col > parcol)
        let parlnum = par2lnum
        let parcol = par2col
    endif
    if par3lnum > parlnum || (par3lnum == parlnum && par3col > parcol)
        let parlnum = par3lnum
        let parcol = par3col
    endif

    " Put the cursor on the match
    if parlnum > 0
        call cursor(parlnum, parcol)
    endif
    return parlnum
endfunction " }}}


" Find the start of a multi-line statement
function! s:StatementStart(lnum) " {{{
    let lnum = a:lnum
    while 1
        if getline(lnum - 1) =~ '\\$'
            let lnum = lnum - 1
        else
            call cursor(lnum, 1)
            let maybe_lnum = s:SearchParensPair()
            if maybe_lnum < 1
                return lnum
            else
                let lnum = maybe_lnum
            endif
        endif
    endwhile
endfunction " }}}


" Find the block starter that matches the current line
function! s:BlockStarter(lnum, block_start_re) " {{{
    let lnum = a:lnum
    let maxindent = indent(prevnonblank(a:lnum))
    while lnum > 1
        let lnum = prevnonblank(lnum - 1)
        if indent(lnum) <= maxindent
            if getline(lnum) =~ a:block_start_re
                return lnum
            else
                let maxindent = indent(lnum)
                " It's not worth going further if we reached the top level
                if maxindent == 0
                    return -1
                endif
            endif
        endif
    endwhile
    return -1
endfunction " }}}
