" Python-mode folding functions

" Notice that folding is based on single line so complex regular expressions
" that take previous line into consideration are not fit for the job.
" Also notice that vim starts processing lines from 1 until the last line.
" using global variables to track down states may not be accurate once the
" file is being edited.

"" REGEX DEFINITIONS {{{
let s:def_regex = g:pymode_folding_regex
let s:blank_regex = '^\s*$'
let s:decorator_regex = '^\s*@\s*\w*\s*\((\|$\)' 
let s:doc_begin_regex = '^\s*[uU]\=\%("""\|''''''\)'
let s:doc_end_regex = '\%("""\|''''''\)\s*$'
" This one is needed for the while loop to count for opening and closing
" docstrings.
let s:doc_general_regex = '\%("""\|''''''\)'
let s:doc_line_regex = '^\s*[uU]\=\("""\|''''''\).\+\1\s*$'
let s:symbol = matchstr(&fillchars, 'fold:\zs.')  " handles multibyte characters
if s:symbol == ''
    let s:symbol = ' '
endif
" ''''''''

"" CONSTANT DEFINITIONS {{{
" Maximum number of lines to search to know if current line is a docstring.
let s:max_line_scan = 150
" }}}

fun! pymode#folding#text() " {{{
    if &foldmethod !=# 'foldexpr' && &foldmethod !=# 'manual'
        return foldtext()
    endif
    let fs = v:foldstart
    while getline(fs) !~ s:def_regex && getline(fs) !~ s:doc_begin_regex
        let fs = nextnonblank(fs + 1)
    endwhile
    if getline(fs) =~ s:doc_end_regex && getline(fs) =~ s:doc_begin_regex
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
    let line = substitute(line, '\c\%([fru]*\%("""\|''''''\)\)', '', '')
    let fillcharcount = windowwidth - len(line) - len(foldedlinecount) + 1
    return line . ' ' . repeat(s:symbol, fillcharcount) . ' ' . foldedlinecount
endfunction "}}}

fun! pymode#folding#expr(lnum) "{{{

    let line = getline(a:lnum)
    let indent = indent(a:lnum)
    let prev_line = getline(a:lnum - 1)
    let next_line = getline(a:lnum + 1)

    " Decorators {{{
    if line =~ s:decorator_regex
        return ">".(indent / &shiftwidth + 1)
    endif "}}}

    " Definition {{{
    if line =~ s:def_regex
        " If indent of this line is greater or equal than line below
        " and previous non blank line does not end with : (that is, is not a
        " definition)
        " Keep the same indentation
        if indent(a:lnum) >= indent(a:lnum+1) && getline(prevnonblank(a:lnum)) !~ ':\s*$'
            return '='
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
            return '='
        else
            " Don't fold if def is a single line
            if indent(nextnonblank(a:lnum + 1)) > indent
                return ">".(indent / &shiftwidth + 1)
            else
                return '='
            endif
        endif
    endif "}}}

    " Docstrings {{{

    if line =~ s:doc_general_regex
        let docstring_description = s:DescribeDocstring(a:lnum)

        if docstring_description['is_docstring']
            " First case: one liners. {{{
            "
            " Notice that an effect of this is that other docstring matches will not
            " be one liners.
            if docstring_description['docstring_type'] == 'single_line'
                return "="
            " }}}

            " Second case: multi liners. {{{
            "
            " Aside from knowing that it is a docstring we need to know if it is
            " a opening docstring or closing because they either open or closes the
            " folding.
            elseif docstring_description['docstring_type'] == 'multi_line' ||
                  \ docstring_description['docstring_type'] == 'module'
                if docstring_description['is_starting_docstring']
                    return ">".(indent / &shiftwidth + 1)
                else
                    return "<".(indent / &shiftwidth + 1)
                endif "}}}
            else
            endif
        endif
    endif

    " }}}

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
                        return 's1'
                    else
                        return '='
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
            if indent(a:lnum + 1) == 0 && next_line !~ s:blank_regex && next_line !~ s:doc_general_regex
                    return 0
            endif
            return -1
        else
            return '='
        endif
    endif " }}}

    return '='

endfunction "}}}

" Auxiliar functions {{{
" Docstring auxiliar functions. {{{
function! s:DescribeDocstring(lnum) " {{{
    " Return a dictionary describing the docstring.
    "
    " What characterizes a docstring? It is a triple quoted string that
    " follows a definition (such as a function or class).
    "
    " To search for a docstring is no simple issue. Strings declared with
    " triple quotes could be arguments inside a function. Example:
    " >>> print(
    " '''This is not a docstring.
    "
    " Indeed not.
    " '''
    " )
    "
    " Returns: 
    "   dict: a dictionary with the following keys:
    "       - is_docstring (bool): v:true if docstring. v:false if not
    "       - docstring_type (bool): 
    "           'single_line' if it is a single line docstring.
    "           'multi_line' if it is a multi line docstring.
    "           'module' if it is a module line docstring.
    "       - is_starting_docstring (bool):
    "           v:true if is a starting docstring.
    "           v:false if is an ending docstring.

    let line = getline(a:lnum)
    let return_dict = {'is_docstring': v:null,
        \ 'docstring_type': v:null,
        \ 'is_starting_docstring': v:null}
    let max_scan_lines = 150

    " Case 01: it is not a docstring.
    if line !~ s:doc_begin_regex
       if line !~ s:doc_end_regex
            let return_dict['is_docstring'] = v:false
            return return_dict
        endif
    endif

    
    " Case 02: it is a single line docstring.
    if line =~ s:doc_line_regex
        let return_dict['is_docstring'] = v:true
        let return_dict['docstring_type'] = 'single_line'
        return return_dict
    else
        let return_dict['docstring_type'] = 'multi_line'
    endif

    " Case 03: it is a multi line docstring.
    let prev_line = getline(a:lnum - 1)
    " Is a starting docstring.
    if s:IsStartingDocstring(a:lnum)
        let return_dict['is_docstring'] = v:true
        let return_dict['is_starting_docstring'] = v:true
        return return_dict
    " Is not a starting docstring.
    else
        " Covers the case of a 'non' is_starting_docstring but it has to have
        " an ending docstring.
        if s:IsEndingDocstring(a:lnum)
            let return_dict['is_docstring'] = v:true
            let return_dict['is_starting_docstring'] = v:false
            return return_dict
        else
            let return_dict['is_docstring'] = v:false
        endif
    endif
endfunction " }}}
function! s:IsModuleDocstring(lnum) " {{{
    " Return v:true if it is a module docstring, v:false otherwise.
    if a:lnum == 1
        return v:true
    else
        return v:false
    endif
endfunction " }}}
function! s:IsStartingDocstring(lnum) " {{{
    " Return v:true if it is a starting docstring, v:false otherwise.
    
    let prev_line = getline(a:lnum - 1)
    if s:IsDefinitionStatement(a:lnum - 1) || s:IsModuleDocstring(a:lnum)
        return v:true
    " Is a starting docstring.
    elseif prev_line =~ s:blank_regex && s:IsDefinitionStatement(a:lnum - 2)
        return v:true
    else
        return v:false
endfunction " }}}
function! s:IsEndingDocstring(lnum) " {{{
    " Return v:true if it is an ending docstring, v:false otherwise.
    
    let i = -1
    let line = getline(a:lnum + i)
    let max_scan_lines = 50

    while ! s:IsStartingDocstring(a:lnum + i)
        if max_scan_lines + i < 0 || getline(a:lnum + i) =~ s:doc_end_regex
            return v:false
        endif
        let i = i - 1
        let line = getline(a:lnum + i)
    endwhile

        return v:true
    
endfunction " }}}
" }}}

" Definition Statements auxiliar functions. {{{
" }}}
function! s:IsDefinitionStatement(lnum) "{{{
    " Return a v:true if line is part of a definition statement.
    "
    " If this line is between matching parenthesis for def statement then
    " it is also a a definition statement.
    "
    " Returns:
    "   bool: v:true if it is part of a definition statement, v:false
    "         otherwise.

    " Cache the result
    if get(b:, 'fold_changenr', -1) == changenr()
        if has_key(b:fold_cache, a:lnum)
            return b:fold_cache[a:lnum]  "If odd then it is an opening
        endif
    else
        let b:fold_changenr = changenr()
        let b:fold_cache = {}
    endif

    let line = getline(a:lnum)

    " Obvious case: is an inline definition statement.
    if line =~ s:def_regex
        return s:SetCache(a:lnum, v:true)
    endif
        
    " Store current cursor position to be restored later.
    let save_cursor = getcurpos()
    let off_number = 1  " Dummy number for now.
    let max_scan_lines = 50
    let end_multiline_def_regex = '):\s*$'
    let i = 0

    while (line !~ s:def_regex && line !~ end_multiline_def_regex)
        if i > max_scan_lines
            return s:SetCache(a:lnum, v:false)
        endif
        let i = i + 1
        let line = getline(a:lnum + i)
    endwhile
    if line =~ s:def_regex
        return s:SetCache(a:lnum, v:false)
    elseif line =~ end_multiline_def_regex
        " Use 'searchpairpos()' to find the matching parenthesis.
        "   flags:
        "       b: backwards
        "       W: don't wrap around the file
        call setpos('.', [0, a:lnum, 1, off_number])
        let matching_position = searchpairpos( '(', '', ')', 'bW')
        call setpos('.', [0] + matching_position + [off_number])
        if getline('.') =~ s:def_regex
            call setpos('.', save_cursor)
            return s:SetCache(a:lnum, v:true)
        else
            call setpos('.', save_cursor)
            return s:SetCache(a:lnum, v:false)
        endif
    endif


    " Put cursor back in corrected position.
endfunction "}}}
function! s:SetCache(lnum, value) "{{{
    " Simple function to add a line to the cache then return the value
    let b:fold_cache[a:lnum] = a:value
    return a:value
endfunction "}}}
" }}}

" Other auxiliar functions {{{
fun! s:BlockStart(lnum) "{{{
    " Note: Make sure to reset cursor position after using this function.
    call cursor(a:lnum, 0)

    " In case the end of the block is indented to a higher level than the def
    " statement plus one shiftwidth, we need to find the indent level at the
    " bottom of that if/for/try/while/etc. block.
    let last_def = searchpos(s:def_regex, 'bcnW')[0]
    if last_def
        let last_def_indent = indent(last_def)
        call cursor(last_def, 0)
        let next_stmt_at_def_indent = searchpos('\v^\s{'.last_def_indent.'}[^[:space:]#]', 'nW')[0]
    else
        let next_stmt_at_def_indent = -1
    endif

    " Now find the class/def one shiftwidth lower than the start of the
    " aforementioned indent block.
    if next_stmt_at_def_indent && next_stmt_at_def_indent < a:lnum
        let max_indent = max([indent(next_stmt_at_def_indent) - &shiftwidth, 0])
    else
        let max_indent = max([indent(prevnonblank(a:lnum)) - &shiftwidth, 0])
    endif
    return searchpos('\v^\s{,'.max_indent.'}(def |class )\w', 'bcnW')[0]
endfunction "}}}
fun! s:BlockEnd(lnum) "{{{
    " Note: Make sure to reset cursor position after using this function.
    call cursor(a:lnum, 0)
    return searchpos('\v^\s{,'.indent('.').'}\S', 'nW')[0] - 1
endfunction "}}}
" }}}
" }}}

" vim: fdm=marker:fdl=0
