function! ai#main(bang, range, line1, line2, mods = "", prompt = "") abort

    let ai_dir = ai#nvim_get_dir()

    let prompt = a:prompt
    let first_word = prompt->split()->get(0, "")

    let cmd = s:cmd_or_abbrev(first_word)
    if cmd != ""
        call call(g:ai_commands[cmd]['func'], [])
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

function! ai#get_last_chat_path(chats_dir = ai#get_chats_dir()) abort
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
    return $"{a:chats_dir}/ai-chat-{localtime()}.md"
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

        if bufname(bufnr) =~# 'ai.nvim/chats/ai-chat-\d\+\.md'
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

    if arg_count == 1
        return providers#get_models()->join("\n") . "\n" . keys(g:ai_commands)->join("\n")
    endi

    return ""
endf

function! s:make_curl_cmd(url, method, headers, body = "") abort
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

function! ai#curl(hostname, url_path, method, headers, body = "", callback = "") abort
    if exists("g:i_am_in_a_test")
        if !exists("g:ai_test_endpoints")
            return $"tests/fixtures/endpoints/{a:url_path}/good.json"
                \ ->readfile()
                \ ->join("\n")
        endi

        let mock_file = g:ai_test_endpoints->get(a:url_path, "")

        if mock_file != ""
            return $"tests/fixtures/endpoints/{a:url_path}/{mock_file}"
                \ ->readfile()
                \ ->join("\n")
        endi
    endi

    let url = $"https://{a:hostname}{a:url_path}"
    let cmd = s:make_curl_cmd(url, a:method, a:headers, a:body)
    call ai#log("curl request", cmd->join(), "sh")
    if a:callback == ""
        let response = system(cmd)
    endif
    call ai#log("curl response", response, "json")

    return response
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

function! ai#handle_log() abort
    execute $"edit {ai#nvim_get_dir()}/log.md"
endf

function! ai#handle_messages() abort
    redir => msg
    silent! messages
    redir END

    let lines = ['```neovim_messages']
    call extend(lines, split(msg, "\n"))
    call add(lines, '```')

    call appendbufline(bufnr(), "$", lines)
endf
