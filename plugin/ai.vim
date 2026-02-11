
let g:ai_model = "gpt-4.1"
let g:ai_localtime = localtime()
let g:ai_job_queue = []
let g:ai_job_running = v:false
let g:ai_responses = []
"let g:ai_dir = ""

let g:ai_commands = {
    \ 'chats': {'func': function('ai#handle_chats'), 'exit': v:true},
    \ 'grep': {'func': function('ai#handle_grep'), 'exit': v:true},
    \ 'log': {'func': function('ai#handle_log'), 'exit': v:true},
    \ 'messages': {'func': function('ai#handle_messages'), 'exit': v:true},
    \}

command!
    \ -complete=customlist,ai#completion
    \ -nargs=*
    \ -range
    \ -bang
    \ Ai
    \ call ai#main("<bang>", <range>, <line1>, <line2>, "<mods>", "<args>")

augroup AiNvimKeyMaps
    autocmd!
    autocmd
        \ BufEnter ai-chat-*.md
        \ nnoremap <buffer> <CR> :silent call providers#submit_chat()<CR>
augroup END
