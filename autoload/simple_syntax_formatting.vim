function! s:deletelines(start, end) abort
    " Function only exists in more recent neovim (0.4+?)
    if exists('*deletebufline')
        call deletebufline('%', a:start, a:end)
    else
        silent! execute a:start . ',' . a:end . 'delete _'
    endif
endfunction

function! s:replacelines(start, end, lines) abort
    if a:start == 1 && a:end == line('$')
        " If we delete all the lines Vim will leave one blank line, which will
        " end up at the end of the file, so we want to make sure we remove that
        " blank line again at the end of the process.
        let l:delete_last_line = 1
    else
        let l:delete_last_line = 0
    endif

    call s:deletelines(a:start, a:end)
    call append(a:start - 1, a:lines)

    if l:delete_last_line
        call s:deletelines(line('$'), line('$'))
    endif
endfunction

function! simple_syntax_formatting#FormatRange(start_line, end_line) abort
    " This function is not designed to work, and will not work well with,
    " on-the-fly formatting as described by :help 'formatexpr' for text being
    " inserted. Therefore, check we are in normal mode first.
    if mode() ==# 'n'
        if exists('b:syntax_format_command')
            echomsg 'Formatting...'
            redraw
            let l:formatter_command = substitute(b:syntax_format_command, '${SHIFTWIDTH}', &shiftwidth, 'g')
            let l:formatter_command = substitute(l:formatter_command, '${TEXTWIDTH}', &textwidth, 'g')
            let l:formatter_command = substitute(l:formatter_command, '${TABSTOP}', &tabstop, 'g')

            let l:view = winsaveview()

            let l:stdin = getbufline(bufnr('%'), a:start_line, a:end_line)
            let l:stdout = systemlist(l:formatter_command, l:stdin)

            if v:shell_error == 0
                let l:number_of_lines = a:end_line - a:start_line + 1

                if l:stdin !=# l:stdout
                    call s:replacelines(a:start_line, a:end_line, l:stdout)
                    echomsg 'Formatted ' . l:number_of_lines . ' lines using "' . l:formatter_command . '".'
                    if exists('*gitgutter#process_buffer')
                        call gitgutter#process_buffer(bufnr(''), 1)
                    endif
                else
                    echomsg 'No change necessary when formatting ' . l:number_of_lines . ' lines.'
                endif
            else
                echohl ErrorMsg | echomsg 'Formatter "' . l:formatter_command . '" failed to run.' | echohl None
            endif

            call winrestview(l:view)
        else
            echohl ErrorMsg | echomsg 'Formatter not defined for this filetype, set b:syntax_format_command in ~/.vim/after/ftplugin/myfiletype.vim' | echohl None
        endif
    else
        return 1
    endif

    return 0
endfunction

function! simple_syntax_formatting#FormatWholeBuffer() abort
    call simple_syntax_formatting#FormatRange(1, line('$'))
endfunction
