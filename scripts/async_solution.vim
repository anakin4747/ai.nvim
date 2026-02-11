
" Always assume token and models are bad for prototyping
function! BadToken()
    return 0
endfunction

function! BadModel()
    return 0
endfunction

let g:task_queue = []
let g:log_file = 'copilot_async_log.txt'

" Logging function: append message to log file and echo
function! LogMsg(msg)
    call writefile([a:msg], g:log_file, 'a')
    echom a:msg
endfunction

" Add a shell command to the queue
function! AddToTaskQueue(cmd)
    call add(g:task_queue, a:cmd)
endfunction

" Run the next task in the queue asynchronously
function! RunTaskQueue()
    if len(g:task_queue) == 0
        call LogMsg('Task queue empty.')
        return
    endif
    let cmd = remove(g:task_queue, 0)
    call LogMsg('Starting task: ' . string(cmd))
    call jobstart(cmd, {
        \ 'on_exit': function('TaskDone'),
        \ 'on_stdout': function('TaskOutput'),
        \ 'on_stderr': function('TaskOutput'),
        \ })
endfunction

" Callback: when a task finishes, run the next
function! TaskDone(job_id, data, event)
    call LogMsg('Task finished: ' . a:job_id)
    call RunTaskQueue()
endfunction

" Callback: log output (stdout/stderr) to file
function! TaskOutput(job_id, data, event)
    if !empty(a:data)
        for line in a:data
            call LogMsg('[' . a:event . '] ' . line)
        endfor
    endif
endfunction

" Mocked shell commands using sleep
let s:curl_token_cmd = ['sh', '-c', 'echo "Mock curl_token"; sleep 1']
let s:curl_models_cmd = ['sh', '-c', 'echo "Mock curl_models"; sleep 1']
let s:curl_chat_cmd = ['sh', '-c', 'echo "Mock curl_chat"; sleep 1']

function! SubmitChat()
    call LogMsg('Submitting chat...')
    if BadToken()
        call AddToTaskQueue(s:curl_token_cmd)
    endif

    if BadModel()
        call AddToTaskQueue(s:curl_models_cmd)
    endif

    call AddToTaskQueue(s:curl_chat_cmd)

    call RunTaskQueue()
endfunction

call SubmitChat()
