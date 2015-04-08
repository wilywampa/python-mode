PymodePython from pymode.lint import code_check

call pymode#tools#signs#init()
call pymode#tools#loclist#init()


fun! pymode#lint#auto() "{{{
    if !pymode#save()
        return 0
    endif
    PymodePython from pymode import auto
    PymodePython auto()
    cclose
    call g:PymodeSigns.clear()
    edit
    call pymode#wide_message("AutoPep8 done.")
endfunction "}}}


fun! pymode#lint#show_errormessage() "{{{
    let loclist = g:PymodeLocList.current()
    if loclist.is_empty()
        return
    endif

    let l = line('.')
    if l == b:pymode_error_line
        return
    endif
    let b:pymode_error_line = l
    if has_key(loclist._messages, l)
        call pymode#wide_message(loclist._messages[l])
    else
        echo
    endif
endfunction "}}}


fun! pymode#lint#toggle() "{{{
    let g:pymode_lint = g:pymode_lint ? 0 : 1
    if g:pymode_lint
        call pymode#wide_message("Code checking is enabled.")
    else
        call pymode#wide_message("Code checking is disabled.")
    end
endfunction "}}}


fun! pymode#lint#check() "{{{
    " DESC: Run checkers on current file.
    "
    let loclist = g:PymodeLocList.current()

    let b:pymode_error_line = -1

    call loclist.clear()

    call pymode#wide_message('Code checking is running ...')

    PymodePython code_check()

    if loclist.is_empty()
        call pymode#wide_message('Code checking is completed. No errors found.')
    endif

    call g:PymodeSigns.refresh(loclist)

    if g:pymode_lint_cwindow
        call loclist.show()
    endif

    call pymode#lint#show_errormessage()
    call pymode#wide_message('Found errors and warnings: ' . len(loclist._loclist))

endfunction " }}}


fun! pymode#lint#tick_queue() "{{{

    python import time
    python print time.time()

    if mode() == 'i'
        if col('.') == 1
            call feedkeys("\<Right>\<Left>", "n")
        else
            call feedkeys("\<Left>\<Right>", "n")
        endif
    else
        call feedkeys("f\e", "n")
    endif
endfunction "}}}

fun! pymode#lint#fix_imports() "{{{
    call pymode#lint#check()
    let loclist = g:PymodeLocList.current()
    let messages = loclist._messages
    let unused = filter(copy(messages), 'stridx(v:val, "W0611") != -1')
    let missing = filter(copy(messages), 'stridx(v:val, "E0602") != -1')

python << EOF
import vim
import cStringIO
import ast
from collections import namedtuple

Import = namedtuple('Import', ['module', 'names', 'alias', 'lrange'])

imports = []
start = None       # Start of import block near top of file
end = None         # End of import block
blank = None       # First blank line after start of import block
first = None       # First regular import or import ... as
last = None        # Last regular import or import ... as
first_from = None  # First from ... import
last_from = None   # Last from ... import

root = ast.parse('\n'.join(vim.current.buffer))

for node in ast.iter_child_nodes(root):
    if blank and node.lineno >= blank:
        break

    if isinstance(node, ast.Import):
        module = []
        if not first:
            first = node.lineno
        last = node.lineno
    elif isinstance(node, ast.ImportFrom):
        module = node.module.split('.')
        if not first_from:
            first_from = node.lineno
        last_from = node.lineno
    else:
        continue

    end = node.lineno
    if '#' not in vim.current.buffer[end-1]:
        while re.search(r'[(\\]', vim.current.buffer[end-1]):
            end += 1

    if not start:
        try:
            blank = next(
                (i for i, l in enumerate(
                    vim.current.buffer) if re.match('^\s*$', l))) + 1
        except StopIteration:
            blank = len(vim.current.buffer)
    start = start or first or first_from

    imports.append(
        Import(
            module, [n.name.split('.') for n in node.names],
            n.asname, (node.lineno, end)))

unused = {int(k): v.replace("W0611 '", '').split("'")[0]
          for k, v in vim.eval('unused').items()
          if start <= int(k) <= end}
missing = [
    m.replace("E0602 undefined name '", '').split("'")[0].strip()
    for m in vim.eval('missing').values()]

keep = {i.lrange: True for i in imports}
for line, _ in unused.items():
    if line in [i.lrange[0] for i in imports]:
        keep[[i.lrange for i in imports if line in i.lrange][0]] = False

lines = ['\n'.join(vim.current.buffer[n[0]-1:n[1]]) for n in keep if keep[n]]

aliases = dict(np='numpy',
               mpl='matplotlib',
               plt='matplotlib.pyplot',
               sio='scipy.io',
               sc='scipy.constants',
               pt='plottools')

for miss in missing:
    if miss in aliases:
        lines.append('import %s as %s' % (aliases[miss], miss))
    else:
        lines.append('import %s' % miss)

lines = sorted(sorted(lines),
               key=lambda x: x.lstrip().startswith('from'))
lines = [l for ls in [l.splitlines() for l in lines] for l in ls]
if lines and start:
    vim.current.buffer[start-1:end] = lines
elif lines:
    vim.current.buffer.append(lines, 0)
EOF
endfunction "}}}

fun! pymode#lint#stop() "{{{
    au! pymode CursorHold <buffer>
endfunction "}}}


fun! pymode#lint#start() "{{{
    au! pymode CursorHold <buffer> call pymode#lint#tick_queue()
    call pymode#lint#tick_queue()
endfunction "}}}
