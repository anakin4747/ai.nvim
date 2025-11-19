
let g:ai_model = ""
let g:ai_localtime = localtime()
"let g:ai_dir = ""

command!
    \ -complete=custom,ai#completion
    \ -nargs=*
    \ -range
    \ -bang
    \ Ai
    \ call ai#main("<bang>", <range>, <line1>, <line2>, "<mods>", "<args>")

augroup AiNvimKeyMaps
    autocmd!
    autocmd
        \ BufEnter ai-chat-*.md
        \ nnoremap <buffer> <CR> :call providers#submit_chat()<CR>
augroup END
