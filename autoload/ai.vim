function! ai#main(bang, range, line1, line2, mods = "", prompt = "") abort

    let ai_dir = ai#nvim_get_dir()

    let prompt = a:prompt
    let first_word = prompt->split()->get(0, "")

    let cmd = s:cmd_or_abbrev(first_word)
    if cmd != ""
        call call(g:ai_commands[cmd]['func'], [prompt])
        if g:ai_commands[cmd]->get('exit', v:false)
            return
        endi
    endi

    let model_passed = s:check_prompt_for_model(prompt)
    if model_passed != ""
        let g:ai_model = model_passed
        " remove first word from prompt
        let prompt = join(split(prompt)[1:])

        if prompt == ""
            return
        endi
    endi

    let chats_dir = $"{ai_dir}/chats"

    if !isdirectory(chats_dir)
        call mkdir(chats_dir, "p")
    endi

    if a:bang == "!" || !s:last_chat_exists(chats_dir)
        let chat_path = s:new_chat_path(chats_dir)
    else
        let chat_path = ai#get_last_chat_path(chats_dir)
    endi

    let original_buf = bufnr()
    let original_filetype = &filetype

    let bufnr = s:open_chat(chat_path, a:mods)

    call setbufline(bufnr, 1, "# ME")
    call setbufline(bufnr, 2, "")

    if prompt != ""
        call appendbufline(bufnr, "$", prompt)
    endi

    if a:range
        let lines = [$"```{original_filetype}"]
        let lines += getbufline(original_buf, a:line1, a:line2)
        let lines += ["```"]
        call appendbufline(bufnr, "$", lines)
    endi

    normal! G

    silent! write

endf

function! s:cmd_or_abbrev(abbrev)
    if empty(a:abbrev)
        return ""
    endi

    for key in keys(g:ai_commands)
        if stridx(key, a:abbrev) == 0
            return key
        endi
    endfo

    return ""
endf

function! ai#nvim_get_dir() abort
    if !exists("g:i_am_in_a_test")
        return $"{stdpath("state")}/ai.nvim"
    endi

    return g:ai_dir
endf

function! ai#get_last_chat_path(chats_dir = $"{ai#nvim_get_dir()}/chats") abort
    let last_chat = system($"ls -1t {a:chats_dir} | head -n1")->trim()
    if v:shell_error != 0 || last_chat == ""
        return ""
    endi

    return $"{a:chats_dir}/{last_chat}"
endf

function! s:last_chat_exists(chats_dir) abort
    return a:chats_dir->ai#get_last_chat_path()->filereadable()
endf

function! s:new_chat_path(chats_dir) abort
    return $"{a:chats_dir}/ai-chat-{strftime("%b-%d-%Y-%T")->tolower()}.md"
endf

function! s:open_chat(chat_path, mods = "") abort

    let open_chat = s:get_open_chat_winnr()

    if open_chat
        execute $"{open_chat}wincmd w"
        execute $"{a:mods} silent! edit {a:chat_path}"
    else
        execute $"{a:mods} split {a:chat_path}"
    endi

    return bufnr()
endf

function! s:get_open_chat_winnr() abort

    for win in range(1, winnr('$'))
        let bufnr = winbufnr(win)
        if bufnr == -1
            continue
        endi

        if bufname(bufnr) =~# 'ai.nvim/chats/ai-chat-.*.md'
            return win
        endif
    endfo

    return 0
endf

function! s:check_prompt_for_model(prompt) abort
    let model = get(split(a:prompt), 0, "")

    if index(providers#get_models(), model) != -1
        return model
    endi

    return ""
endf

function! ai#completion(arglead, cmdline, curpos) abort
    let arg_count = a:cmdline->split()->len()

    if arg_count > 2 || (arg_count == 2 && empty(a:arglead))
        return []
    endif

    let possible_completions = []
    let possible_completions += keys(g:ai_commands)
    let possible_completions += providers#get_models()

    if !empty(a:arglead)
        call filter(possible_completions,
            \ {_, val -> stridx(val, a:arglead) == 0})
    endif

    return possible_completions
endf

function! ai#build_curl_cmd(url, method, headers, body = "") abort
    let cmd = [
        \   "curl",
        \       "--request", a:method,
        \       "--url", a:url,
        \       "--silent",
        \]

    if type(a:headers) != v:t_list
        throw "a:headers is not a list"
    endi

    for h in a:headers
        let cmd += ["--header", h]
    endfo

    if type(a:body) != v:t_string
        throw "a:body is not a string"
    endi

    if a:body != ""
        let cmd += ["--data", a:body]
    endi

    return cmd
endf

function! ai#log(msg, data, datatype = "") abort
    let loggin = v:true

    if !loggin
        return
    endi

    let ai_dir = ai#nvim_get_dir()
    let log_path = $"{ai_dir}/log.md"

    let log_msg = ["", "",
        \ $"---START---",
        \ $"{strftime('%Y-%m-%d %H:%M:%S')}",
        \ $"message: '{a:msg}'",
        \ $"stacktrace:",
        \]

    let stacktrace = getstacktrace()
    for frame in stacktrace
        let filepath = frame->get('filepath', '')
        let lnum = frame->get('lnum', '')
        let Func = frame->get('funcref', '')
            \ ->string()->substitute("function('\\(.*\\)')", '\1()', '')
        let log_msg += [$"  {filepath}:{lnum}:{Func}"]
    endfo

    if a:data != ""
        let log_msg += ["", $"```{a:datatype}", a:data, "```"]
    endi

    let log_msg += ["----END----", ""]

    if !filereadable(ai_dir)
        call mkdir(ai_dir, "p")
    endi

    call writefile(log_msg, log_path, 'a')
endf

function! ai#enqueue_job(job) abort
    if len(g:ai_job_queue) >= 3
        throw "no more than 3 jobs are needed at a time"
    endi
    if a:job->get('on_stdout')->type() != v:t_func
        return v:false
    endi
    if a:job->get('cmd')->type() != v:t_list
        return v:false
    endi
    call add(g:ai_job_queue, a:job)
    return v:true
endf

function! ai#wait_for_jobs() abort
    while g:ai_job_running
        sleep 10m
    endw
endf

function! s:run_next_job(_, __, ___) abort
    let g:ai_job_running = v:false
    call ai#run_job_queue()
endf

" TODO: move this to test code
function! s:mock_jobstart(cmd, opts) abort

    let url = a:cmd[index(a:cmd, "--url") + 1]
    let url_path = substitute(url, 'https://.*\.com\(/.*\)', '\1', '')

    let fixture_paths = [$"tests/fixtures/endpoints/{url_path}/good.json"]

    if exists("g:ai_test_endpoints")
        let mock_file = g:ai_test_endpoints->get(url_path, "")

        if type(mock_file) == v:t_list
            let fixture_paths = []
            for path in mock_file
                let fixture_paths += [$"tests/fixtures/endpoints/{url_path}/{path}"]
            endfo
        endi

        call ai#log($"url: '{url}' url_path: '{url_path}' mock_file: '{mock_file}' mock_file type: '{type(mock_file)}' url_path: '{url_path}' ai_test_endpoints: '{g:ai_test_endpoints}'")

        if type(mock_file) == v:t_string && mock_file != ""
            let fixture_paths = [$"tests/fixtures/endpoints/{url_path}/{mock_file}"]
        endi

        call ai#log($"here")
    endi

    let job = ['cat'] + fixture_paths

    call ai#log($"job: '{job}'")

    call jobstart(job, a:opts)
endf

function! ai#run_job_queue() abort
    if g:ai_job_running
        return
    endi

    if len(g:ai_job_queue) == 0
        return
    endif

    let g:ai_job_running = v:true
    let job = remove(g:ai_job_queue, 0)

    let job_runner = 'jobstart'

    if exists("g:i_am_in_a_test")
        let job_runner = 's:mock_jobstart'
    endi

    let job_runner_args = [job.cmd]
    let job_opts = {
        \   'on_exit': function('s:run_next_job'),
        \   'on_stdout': job.on_stdout,
        \ }
    if exists("job.stdout_buffered")
        call extend(job_opts, #{stdout_buffered: job.stdout_buffered})
    endi

    let job_runner_args += [job_opts]

    call call(job_runner, job_runner_args)
endf

function! ai#handle_chats(...) abort
    let dir = $"{ai#nvim_get_dir()}/chats/"
    let chats = systemlist($"ls -1t {dir}")

    let items = []
    for fname in chats
        call add(items, #{filename: dir . fname})
    endfo

    call setqflist(items, 'r')
    copen
endf

function! ai#handle_grep(...) abort
    let pattern = a:000->get(0)->split()->get(1, "")
    if pattern == ""
        echohl ErrorMsg
        echomsg ':Ai grep requires a search pattern'
        echohl None
        return
    endi
    execute $"vimgrep /{pattern}/ {ai#nvim_get_dir()}/chats/*"
endf

function! ai#handle_log(...) abort
    execute $"edit {ai#nvim_get_dir()}/log.md"
endf

function! ai#handle_messages(...) abort
    redir => msg
    silent! messages
    redir END

    let lines = ['```neovim_messages']
    call extend(lines, split(msg, "\n"))
    call add(lines, '```')

    call appendbufline(bufnr(), "$", lines)
endf
