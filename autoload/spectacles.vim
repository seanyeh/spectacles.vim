if exists('g:autoloaded_spectacles')
  finish
endif
let g:autoloaded_spectacles = 1

if !exists('g:spectacles_rspec_command')
    let g:spectacles_rspec_command = 'rspec'
endif
if !exists('g:spectacles_rspec_run_background')
    let g:spectacles_rspec_run_background = 0
endif

" Navigate methods
function! s:NavigateHelper(function_name, ...)
    let line_number = call(a:function_name, a:000)
    if line_number
        exe 'normal! '.line_number.'gg'
    endif
endfunction

function! spectacles#NavigateParentTop()
    call s:NavigateHelper('spectacles#FindParent', line('.'), -1)
endfunction

function! spectacles#NavigateParentBottom()
    call s:NavigateHelper('spectacles#FindParent', line('.'), 1)
endfunction

function! spectacles#NavigateDefinition()
    call s:NavigateHelper('spectacles#FindDefinition', line('.'))
endfunction

function! spectacles#NavigateRootParent()
    call s:NavigateHelper('spectacles#FindRootParentAttribute', line('.'), 'line')
endfunction

" Search functions

" Return the line number of the closest line with less indentation
" If direction is -1, search upwards
" If direction is 1, search downwards
function! spectacles#FindParent(start_line_number, direction)
    let line_number = a:start_line_number
    let current_indentation = indent(line_number)
    while 1
        let line_number += a:direction
        if line_number <= 0 || line_number > line('$')
            return 0
        endif

        if indent(line_number) < current_indentation && getline(line_number) !~# '\v^\s*$'
            return line_number
        endif
    endwhile
endfunction

function! spectacles#FindDefinition(line_number)
    if !spectacles#IsSharedExample(a:line_number)
        return 0
    endif

    let name = spectacles#GetString(a:line_number)
    if len(name)
        " Check for both double quotes and single quotes
        let result = search('\vshared_examples\s+"'.name.'"', 'n')
        if !result
            let result = search('\vshared_examples\s+'."'".name."'", 'n')
        endif
        return result
    endif
endfunction

function! spectacles#IsTestHeader(line_number)
    return spectacles#MatchFirst(a:line_number, ["describe", "context", "it"])
endfunction

function! spectacles#IsTestEnd(line_number)
    return spectacles#MatchFirst(a:line_number, ["end"])
endfunction

function! spectacles#IsSharedExample(line_number)
    return spectacles#MatchFirst(a:line_number, ["include_examples", "it_behaves_like", "it_should_behave_like"])
endfunction

function! spectacles#FindAncestry(line_number)
    if !a:line_number
        return []
    endif

    let current_indentation = indent(a:line_number)
    let current_string = spectacles#GetString(a:line_number)

    let current = []
    if spectacles#IsTestHeader(a:line_number) && len(current_string)
        let current = [{'line': a:line_number, 'indent': current_indentation, 'string': current_string}]
    endif

    let parent_line = spectacles#FindParent(a:line_number, -1)
    return spectacles#FindAncestry(parent_line) + current
endfunction

function! spectacles#FindRootParent(line_number)
    let ancestry = spectacles#FindAncestry(a:line_number)

    for info in ancestry
        if info['indent'] > 0
            return info
        endif
    endfor

    return {}
endfunction

function! spectacles#FindRootParentAttribute(line_number, attribute)
    let parent = spectacles#FindRootParent(a:line_number)
    if len(parent)
        return parent[a:attribute]
    endif
endfunction

" Helper functions

" Returns whether the first word in the given matches the word_list
function! spectacles#MatchFirst(line_number, word_list)
    let line = trim(getline(a:line_number))
    let words = split(line)

    if len(words) >= 1 && index(a:word_list, words[0]) != -1
        return 1
    endif

    return 0
endfunction

function! spectacles#GetString(line_number)
    let line = trim(getline(a:line_number))

    " Regex for unescaped string
    let match_double = matchstrpos(line, '\v(\\)@<!".*[^\\]"')
    let match_single = matchstrpos(line, '\v(\\)@<!'."'".'.*[^\\]'."'")

    " If match both double/single quoted strings, choose earlier one
    if len(match_double[0]) && len(match_single[0])
        if match_double[1] < match_single[1]
            return match_double[0][1:-2]
        else
            return match_single[0][1:-2]
        endif
    elseif len(match_double[0])
        return match_double[0][1:-2]
    elseif len(match_single[0])
        return match_single[0][1:-2]
    else
        return ""
    endif

    if len(match_double[0]) && match_double[1] < match_single[1]
    elseif len(match_single[1])
        return match_single[0][1:-2]
    endif

    return ""
endfunction

function! spectacles#RunTest(...)
    let filename = a:0 == 0 ? expand('%') : a:1
    let cmd = g:spectacles_rspec_command.' "'.filename.'"'

    if g:spectacles_rspec_run_background
        call system(cmd)
    else
        exe 'terminal '.cmd
    endif
endfunction

function! spectacles#RunCurrentTest()
    call spectacles#RunTest(expand('%').':'.line('.'))
endfunction
