
let g:ai_model = "gpt-4.1"
let g:ai_localtime = localtime()
let g:ai_job_queue = []
let g:ai_job_running = v:false
let g:ai_responses = []
"let g:ai_dir = ""

" Default model parameters (per-model overrides stored as nested dict)
let g:ai_model_params = {}
let s:ai_model_param_defaults = {
    \ 'temperature': 0.1,
    \ 'top_p': 1,
    \ 'max_tokens': 16384,
    \ 'n': 1,
    \}
let g:ai_model_param_defaults = s:ai_model_param_defaults

let g:ai_commands = {
    \ 'chats': {'func': function('ai#handle_chats'), 'exit': v:true},
    \ 'clean': {'func': function('ai#handle_clean'), 'exit': v:true},
    \ 'cleanall': {'func': function('ai#handle_cleanall'), 'exit': v:true},
    \ 'grep': {'func': function('ai#handle_grep'), 'exit': v:true},
    \ 'log': {'func': function('ai#handle_log'), 'exit': v:true},
    \ 'messages': {'func': function('ai#handle_messages'), 'exit': v:true},
    \ 'mrproper': {'func': function('ai#handle_mrproper'), 'exit': v:true},
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
