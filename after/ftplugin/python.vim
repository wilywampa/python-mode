if !g:pymode
    finish
endif

if g:pymode_motion

    if !&magic
        if g:pymode_warning
            call pymode#error("Pymode motion requires `&magic` option. Enable them or disable g:pymode_motion")
        endif
        finish
    endif

    try
        call CountJump#Motion#MakeBracketMotion('<buffer>', '', '',
            \ '^\(class\|def\)\s',
            \ '^\ze.*\n\(class\|def\)\s', 0)
    catch /^Vim\%((\a\+)\)\=:E117/
        nnoremap <buffer> ]]  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
        nnoremap <buffer> [[  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
        onoremap <buffer> ]]  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
        onoremap <buffer> [[  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
        vnoremap <buffer> ]]  0:call pymode#motion#vmove('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
        vnoremap <buffer> [[  0:call pymode#motion#vmove('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
    endtry

    nnoremap <buffer> ]C :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', '')<CR>
    nnoremap <buffer> [C :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', 'b')<CR>
    nnoremap <buffer> <expr> ]c  &diff? "]c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', '')\<CR>"
    nnoremap <buffer> <expr> [c  &diff? "[c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', 'b')\<CR>"
    nnoremap <buffer> ]m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', '')<CR>
    nnoremap <buffer> [m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', 'b')<CR>

    onoremap <buffer> ]C  :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', '')<CR>
    onoremap <buffer> [C  :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', 'b')<CR>
    onoremap <buffer> <expr> ]c  &diff? "]c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', '')\<CR>"
    onoremap <buffer> <expr> [c  &diff? "[c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', 'b')\<CR>"
    onoremap <buffer> ]m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', '')<CR>
    onoremap <buffer> [m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', 'b')<CR>

    vnoremap <buffer> ]C  0:call pymode#motion#vmove('^<Bslash>s*class<Bslash>s', '')<CR>
    vnoremap <buffer> [C  0:call pymode#motion#vmove('^<Bslash>s*class<Bslash>s', 'b')<CR>
    vnoremap <buffer> <expr> ]c &diff? "]c" : "0:call pymode#motion#vmove('^\<Bslash>s*class\<Bslash>s', '')\<CR>"
    vnoremap <buffer> <expr> [c &diff? "[c" : "0:call pymode#motion#vmove('^\<Bslash>s*class\<Bslash>s', 'b')\<CR>"
    vnoremap <buffer> ]m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', '')<CR>
    vnoremap <buffer> [m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', 'b')<CR>
    vnoremap <buffer> ]m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', '')<CR>
    vnoremap <buffer> [m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', 'b')<CR>

    onoremap <buffer> C  :<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 0)<CR>
    onoremap <buffer> ac :<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 0)<CR>
    onoremap <buffer> ic :<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 1)<CR>
    vnoremap <buffer> ac 0:<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 0)<CR>
    vnoremap <buffer> ic 0:<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 1)<CR>

    onoremap <buffer> M  :<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 0)<CR>
    onoremap <buffer> am :<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 0)<CR>
    onoremap <buffer> im :<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 1)<CR>
    vnoremap <buffer> am 0:<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 0)<CR>
    vnoremap <buffer> im 0:<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 1)<CR>

    onoremap <buffer> I  :<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 0)<CR>
    onoremap <buffer> ai :<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 0)<CR>
    onoremap <buffer> ii :<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 1)<CR>
    vnoremap <buffer> ai 0:<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 0)<CR>
    vnoremap <buffer> ii 0:<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 1)<CR>

endif

if g:pymode_rope && g:pymode_rope_completion

    setlocal omnifunc=pymode#rope#completions

    if g:pymode_rope_completion_bind != ""
        exe "inoremap <silent> <buffer> " . g:pymode_rope_completion_bind . " <C-R>=pymode#rope#complete(0)<CR>"
        if tolower(g:pymode_rope_completion_bind) == '<c-space>'
            exe "inoremap <silent> <buffer> <Nul> <C-R>=pymode#rope#complete(0)<CR>"
        endif
    end

end
