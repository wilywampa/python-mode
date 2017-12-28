" Notice that folding is based on single line so complex regular expressions
" that take previous line into consideration are not fit for the job.

" Regex definitions for correct folding
let s:def_regex = g:pymode_folding_regex
let s:blank_regex = '^\s*$'
" Spyder, a very popular IDE for python has a template which includes
" '@author:' ; thus the regex below.
let s:decorator_regex = '^\s*@\s*\w*\s*\((\|$\)'
let s:docstring_begin_regex = '^\s*[uUrR]\=\%("""\|''''''\)'
let s:docstring_end_regex = '\%("""\|''''''\)\s*$'
" This one is needed for the while loop to count for opening and closing
" docstrings.
let s:docstring_general_regex = '\%("""\|''''''\)'
let s:docstring_line_regex = '^\s*[uUrR]\=\("""\|''''''\).\+\1\s*$'
let s:symbol = matchstr(&fillchars, 'fold:\zs.')  " handles multibyte characters
if s:symbol == ''
    let s:symbol = ' '
endif
" ''''''''


fun! pymode#folding#text() " {{{
    if &foldmethod !=# 'foldexpr' && &foldmethod !=# 'manual'
        return foldtext()
    endif
    let fs = v:foldstart
    while getline(fs) !~ s:def_regex && getline(fs) !~ s:docstring_begin_regex
        let fs = nextnonblank(fs + 1)
    endwhile
    if getline(fs) =~ s:docstring_end_regex && getline(fs) =~ s:docstring_begin_regex
        let fs = nextnonblank(fs + 1)
    endif
    let line = getline(fs)

    let has_numbers = &number || &relativenumber
    let nucolwidth = &fdc + has_numbers * &numberwidth
    let windowwidth = winwidth(0) - nucolwidth - 6
    let foldedlinecount = v:foldend - v:foldstart

    " expand tabs into spaces
    let onetab = strpart('          ', 0, &tabstop)
    let line = substitute(line, '\t', onetab, 'g')

    let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
    let line = substitute(line, '\%([fFuUrR]*\%("""\|''''''\)\)', '', '')
    let fillcharcount = windowwidth - len(line) - len(foldedlinecount) + 1
    return line . ' ' . repeat(s:symbol, fillcharcount) . ' ' . foldedlinecount
endfunction "}}}

fun! pymode#folding#expr(lnum) "{{{

    let l:return_value = pymode#folding#foldcase(a:lnum)['foldlevel']

    return l:return_value

endfunction "}}}

fun! pymode#folding#foldcase(lnum) "{{{
    " Return a dictionary with a brief description of the foldcase and the
    " evaluated foldlevel: {'foldcase': 'case description', 'foldlevel': 1}.

    let l:foldcase = 'general'
    let l:foldlevel = '='

    let line = getline(a:lnum)
    let indent = indent(a:lnum)
    let prev_line = getline(a:lnum - 1)
    let next_line = getline(a:lnum + 1)

    " Decorators {{{
    if line =~ s:decorator_regex
        let l:foldcase = 'decorator declaration'
        let l:foldlevel = ">".(indent / &shiftwidth + 1)
        return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
    endif "}}}

    " Definition {{{
    if line =~ s:def_regex
        " If indent of this line is greater or equal than line below
        " and previous non blank line does not end with : (that is, is not a
        " definition)
        " Keep the same indentation
        if indent(a:lnum) >= indent(a:lnum+1) && getline(prevnonblank(a:lnum)) !~ ':\s*$'
            let l:foldcase = 'definition'
            let l:foldlevel = '='
            return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
        endif
        " Check if last decorator is before the last def
        let decorated = 0
        let lnum = a:lnum - 1
        while lnum > 0
            if getline(lnum) =~ s:def_regex
                break
            elseif getline(lnum) =~ s:decorator_regex
                let decorated = 1
                break
            endif
            let lnum -= 1
        endwhile
        if decorated
            let l:foldcase = 'decorated function declaration'
            let l:foldlevel = '='
            return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
        else
            " Don't fold if def is a single line
            if indent(nextnonblank(a:lnum + 1)) > indent
                let l:foldcase = 'function declaration'
                let l:foldlevel = ">".(indent / &shiftwidth + 1)
                return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
            else
                let l:foldcase = 'one-liner function'
                let l:foldlevel = '='
                return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
            endif
        endif
    endif "}}}

    " Docstrings {{{

    if line =~ s:docstring_begin_regex && line !~ s:docstring_line_regex && line !~ '\w.\+[fFrRuU]\?\%("""\|''''''\)\s*$'
        let curpos = getpos('.')
        try
            call cursor(a:lnum, 0)
            call search('\v\)\s*(\s*-\>.*)?:', 'bW')
            let [startline, _] = searchpairpos('(', '', ')', 'b')
            if getline(startline) =~ s:def_regex
                let doc_begin_line = searchpos(s:docstring_begin_regex, 'nW')[0]
                if doc_begin_line == a:lnum
                    let l:foldcase = 'start of docstring'
                    let l:foldlevel = ">".(indent / &shiftwidth + 1)
                    return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
                endif
            endif
        finally
            call setpos('.', curpos)
        endtry
    endif

    if line =~ s:docstring_end_regex && line !~ s:docstring_line_regex
        let l:foldcase = 'open multiline docstring'
        let l:foldlevel = "<".(indent / &shiftwidth + 1)
        return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
    endif

    " Nested Definitions {{{
    " Handle nested defs but only for files shorter than
    " g:pymode_folding_nest_limit lines due to performance concerns
    if line('$') < g:pymode_folding_nest_limit && indent(prevnonblank(a:lnum))
        let curpos = getpos('.')
        try
            let last_block = s:BlockStart(a:lnum)
            let last_block_indent = indent(last_block)

            " Check if last class/def is not indented and therefore can't be
            " nested.
            if last_block_indent
                call cursor(a:lnum, 0)
                let next_def = searchpos(s:def_regex, 'nW')[0]
                let next_def_indent = next_def ? indent(next_def) : -1
                let last_block_end = s:BlockEnd(last_block)

                " If the next def has greater indent than the previous def, it
                " is nested one level deeper and will have its own fold. If
                " the class/def containing the current line is on the first
                " line it can't be nested, and if this block ends on the last
                " line, it contains no trailing code that should not be
                " folded. Finally, if the next non-blank line after the end of
                " the previous def is less indented than the previous def, it
                " is not part of the same fold as that def. Otherwise, we know
                " the current line is at the end of a nested def.
                if next_def_indent <= last_block_indent && last_block > 1 && last_block_end < line('$')
                    \ && indent(nextnonblank(last_block_end)) >= last_block_indent

                    " Include up to one blank line in the fold
                    if getline(last_block_end) =~ s:blank_regex
                        let fold_end = min([prevnonblank(last_block_end - 1), last_block_end]) + 1
                    else
                        let fold_end = last_block_end
                    endif
                    if a:lnum == fold_end
                        let l:foldcase = 'after nested def'
                        let l:foldlevel = 's1'
                        return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
                    else
                        let l:foldcase = 'inside nested def'
                        let l:foldlevel = '='
                        return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
                    endif
                endif
            endif
        finally
            call setpos('.', curpos)
        endtry
    endif " }}}

    " Blank Line {{{
    if line =~ s:blank_regex
        if prev_line =~ s:blank_regex
            if indent(a:lnum + 1) == 0 && next_line !~ s:blank_regex && next_line !~ s:docstring_general_regex
                if s:Is_opening_folding(a:lnum)
                    " echom a:lnum
                    let l:foldcase = 'case 1'
                    let l:foldlevel = "="
                    return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
                else
                    " echom "not " . a:lnum
                    let l:foldcase = 'case 2'
                    let l:foldlevel = 0
                    return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
                endif
            endif
            let l:foldcase = 'case 3'
            let l:foldlevel = -1
            return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
        else
            let l:foldcase = 'case 4'
            let l:foldlevel = '='
            return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
        endif
    endif " }}}

    if indent == 0
        let l:foldcase = 'general with no indent'
        let l:foldlevel = 0
        return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}
    endif

    return {'foldcase': l:foldcase, 'foldlevel': l:foldlevel}

endfunction "}}}

fun! s:BlockStart(lnum) "{{{
    " Returns the definition statement which encloses the current line.

    let line = getline(a:lnum)
    if line !~ s:blank_regex
        let l:inferred_indent = indent(a:lnum)
    else
        let l:inferred_indent = prevnonblank(a:lnum)
    endif

    " Note: Make sure to reset cursor position after using this function.
    call cursor(a:lnum, 0)

    " In case the end of the block is indented to a higher level than the def
    " statement plus one shiftwidth, we need to find the indent level at the
    " bottom of that if/for/try/while/etc. block.
    " Flags from searchpos() (same as search()):
    " b: search Backward instead of forward
    " n: do Not move the cursor
    " W: don't Wrap around the end of the file
    let previous_definition = searchpos(s:def_regex, 'bnW')
    if previous_definition != [0, 0]
        " Lines that are blank have zero indent.
        while previous_definition != [0, 0]
                \ && indent(previous_definition[0]) >= l:inferred_indent
            let previous_definition = searchpos(s:def_regex, 'bnW')
            call cursor(previous_definition[0] - 1, 0)
        endwhile
    endif
    let last_def = previous_definition[0]
    if last_def
        call cursor(last_def, 0)
        let last_def_indent = indent(last_def)
        call cursor(last_def, 0)
        let next_stmt_at_def_indent = searchpos('\v^\s{'.last_def_indent.'}[^[:space:]#]', 'nW')[0]
    else
        let next_stmt_at_def_indent = -1
    endif

    " Now find the class/def one shiftwidth lower than the start of the
    " aforementioned indent block.
    if next_stmt_at_def_indent && (next_stmt_at_def_indent < a:lnum)
        let max_indent = max([indent(next_stmt_at_def_indent) - &shiftwidth, 0])
    else
        let max_indent = max([indent(prevnonblank(a:lnum)) - &shiftwidth, 0])
    endif

    let result = searchpos('\v^\s{,'.max_indent.'}(def |class )\w', 'bcnW')[0]

    return result

endfunction "}}}
function! Blockstart(x)
    let save_cursor = getcurpos()
    return s:BlockStart(a:x)
    call setpos('.', save_cursor)
endfunction

fun! s:BlockEnd(lnum) "{{{
    " Note: Make sure to reset cursor position after using this function.
    call cursor(a:lnum, 0)
    return searchpos('\v^\s{,'.indent('.').'}\S', 'nW')[0] - 1
endfunction "}}}
function! Blockend(lnum)
    let save_cursor = getcurpos()
    return s:BlockEnd(a:lnum)
    call setpos('.', save_cursor)
endfunction

function! s:Is_opening_folding(lnum) "{{{
    " Helper function to see if multi line docstring is opening or closing.

    " Cache the result so the loop runs only once per change.
    if get(b:, 'fold_changenr', -1) == changenr()
        return b:fold_cache[a:lnum - 1]  "If odd then it is an opening
    else
        let b:fold_changenr = changenr()
        let b:fold_cache = []
    endif

    " To be analized if odd/even to inform if it is opening or closing.
    let fold_odd_even = 0
    " To inform is already has an open docstring.
    let has_open_docstring = 0
    " To help skipping ''' and """ which are not docstrings.
    let extra_docstrings = 0

    " The idea of this part of the function is to identify real docstrings and
    " not just triple quotes (that could be a regular string).

    " Iterater over all lines from the start until current line (inclusive)
    for i in range(1, line('$'))

        let i_line = getline(i)

        if i_line =~ s:docstring_begin_regex && ! has_open_docstring
            " This causes the loop to continue if there is a triple quote which
            " is not a docstring.
            if extra_docstrings > 0
                let extra_docstrings = extra_docstrings - 1
            else
                let has_open_docstring = 1
                let fold_odd_even = fold_odd_even + 1
            endif
        " If it is an end doc and has an open docstring.
        elseif i_line =~ s:docstring_end_regex && has_open_docstring
            let has_open_docstring = 0
            let fold_odd_even = fold_odd_even + 1

        elseif i_line =~ s:docstring_general_regex
            let extra_docstrings = extra_docstrings + 1
        endif

        call add(b:fold_cache, fold_odd_even % 2)

    endfor

    return b:fold_cache[a:lnum]

endfunction "}}}

" vim: fdm=marker:fdl=0
