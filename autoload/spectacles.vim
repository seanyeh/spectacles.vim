if exists('g:autoloaded_spectacles')
  finish
endif
let g:autoloaded_spectacles = 1

" Navigate methods
function! spectacles#NavigateHelper(function_name, ...)
    let line_number = call(a:function_name, a:000)
    if line_number
        exe 'normal! '.line_number.'gg'
    endif
endfunction

function! spectacles#NavigateParentTop()
    call spectacles#NavigateHelper('spectacles#FindParent', -1)
endfunction

function! spectacles#NavigateParentBottom()
    call spectacles#NavigateHelper('spectacles#FindParent', 1)
endfunction

function! spectacles#NavigateDefinition()
    call spectacles#NavigateHelper('spectacles#FindDefinition', line('.'))
endfunction

" Search functions

" Return the line number of the closest line with less indentation
" If direction is -1, search upwards
" If direction is 1, search downwards
function! spectacles#FindParent(direction)
    let line_number = line('.')
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
        return 0
    endif

    if len(match_double[0]) && match_double[1] < match_single[1]
    elseif len(match_single[1])
        return match_single[0][1:-2]
    endif

    return 0
endfunction
