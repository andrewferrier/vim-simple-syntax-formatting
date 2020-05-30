if exists('g:loaded_simple_syntax_formatting') || &compatible || v:version < 700
    finish
endif

let g:loaded_simple_syntax_formatting = '0.1'

set formatexpr=simple_syntax_formatting#FormatRange(v:lnum,v:lnum+v:count-1)

nnoremap <silent> <Plug>SSFFormatWholeBuffer :<C-U>call simple_syntax_formatting#FormatWholeBuffer()<CR>
