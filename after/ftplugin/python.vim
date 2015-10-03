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
            \ '^\(class\|\(cp\?\)\?def\)\s',
            \ '^\ze.*\n\(class\|\(cp\?\)\?def\)\s', 0)
    catch /^Vim\%((\a\+)\)\=:E117/
        nnoremap <silent> <buffer> ]]  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
        nnoremap <silent> <buffer> [[  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
        onoremap <silent> <buffer> ]]  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
        onoremap <silent> <buffer> [[  :<C-U>call pymode#motion#move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
        vnoremap <silent> <buffer> ]]  0:call pymode#motion#vmove('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
        vnoremap <silent> <buffer> [[  0:call pymode#motion#vmove('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
    endtry

    nnoremap <silent> <buffer> ]C :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', '')<CR>
    nnoremap <silent> <buffer> [C :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', 'b')<CR>
    nnoremap <silent> <buffer> <expr> ]c  &diff? "]c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', '')\<CR>"
    nnoremap <silent> <buffer> <expr> [c  &diff? "[c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', 'b')\<CR>"
    nnoremap <silent> <buffer> ]m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', '')<CR>
    nnoremap <silent> <buffer> [m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', 'b')<CR>

    onoremap <silent> <buffer> ]C  :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', '')<CR>
    onoremap <silent> <buffer> [C  :<C-U>call pymode#motion#move('<Bslash>v^<Bslash>s*class<Bslash>s', 'b')<CR>
    onoremap <silent> <buffer> <expr> ]c  &diff? "]c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', '')\<CR>"
    onoremap <silent> <buffer> <expr> [c  &diff? "[c" : ":\<C-U>call pymode#motion#move('\<Bslash>v^\<Bslash>s*class\<Bslash>s', 'b')\<CR>"
    onoremap <silent> <buffer> ]m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', '')<CR>
    onoremap <silent> <buffer> [m  :<C-U>call pymode#motion#move('^<Bslash>s*def<Bslash>s', 'b')<CR>

    vnoremap <silent> <buffer> ]C  0:call pymode#motion#vmove('^<Bslash>s*class<Bslash>s', '')<CR>
    vnoremap <silent> <buffer> [C  0:call pymode#motion#vmove('^<Bslash>s*class<Bslash>s', 'b')<CR>
    vnoremap <silent> <buffer> <expr> ]c &diff? "]c" : "0:call pymode#motion#vmove('^\<Bslash>s*class\<Bslash>s', '')\<CR>"
    vnoremap <silent> <buffer> <expr> [c &diff? "[c" : "0:call pymode#motion#vmove('^\<Bslash>s*class\<Bslash>s', 'b')\<CR>"
    vnoremap <silent> <buffer> ]m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', '')<CR>
    vnoremap <silent> <buffer> [m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', 'b')<CR>
    vnoremap <silent> <buffer> ]m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', '')<CR>
    vnoremap <silent> <buffer> [m  0:call pymode#motion#vmove('^<Bslash>s*def<Bslash>s', 'b')<CR>

    onoremap <silent> <buffer> C  :<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 0)<CR>
    onoremap <silent> <buffer> ac :<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 0)<CR>
    onoremap <silent> <buffer> ic :<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 1)<CR>
    vnoremap <silent> <buffer> ac 0:<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 0)<CR>
    vnoremap <silent> <buffer> ic 0:<C-U>call pymode#motion#select('^<Bslash>s*class<Bslash>s', 1)<CR>

    onoremap <silent> <buffer> M  :<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 0)<CR>
    onoremap <silent> <buffer> am :<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 0)<CR>
    onoremap <silent> <buffer> im :<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 1)<CR>
    vnoremap <silent> <buffer> am 0:<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 0)<CR>
    vnoremap <silent> <buffer> im 0:<C-U>call pymode#motion#select('^<Bslash>s*def<Bslash>s', 1)<CR>

    onoremap <silent> <buffer> I  :<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 0)<CR>
    onoremap <silent> <buffer> ai :<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 0)<CR>
    onoremap <silent> <buffer> ii :<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 1)<CR>
    vnoremap <silent> <buffer> ai 0:<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 0)<CR>
    vnoremap <silent> <buffer> ii 0:<C-U>call pymode#motion#select('<Bslash>v^<Bslash>s*(class<Bar>def<Bar>elif<Bar>else<Bar>except<Bar>finally<Bar>for<Bar>if<Bar>try<Bar>while<Bar>with)>', 1)<CR>

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
