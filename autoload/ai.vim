
function! ai#main(bang, range, line1, line2, mods = "", prompt = "") abort

    let prompt = a:prompt
    let model_passed = s:check_prompt_for_model(prompt)
    if model_passed != ""
        let g:ai_model = model_passed
        " remove first word from prompt
        let prompt = join(split(prompt)[1:])

        if prompt == ""
            return
        endi
    endi

    let chats_dir = ai#get_chats_dir()

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

function! ai#get_home_dir()
    if exists("g:ai_home_dir")
        return g:ai_home_dir
    endi

    return expand("$HOME")
endf

function! ai#nvim_get_dir()
    if exists("g:ai_dir")
        return g:ai_dir
    endi

    return $"{stdpath("state")}/ai.nvim"
endf

function! ai#get_chats_dir()
    return $"{ai#nvim_get_dir()}/chats"
endf

function! ai#get_last_chat_path(chats_dir = ai#get_chats_dir())
    let last_chat = system($"ls -1t {a:chats_dir} | head -n1")->trim()
    if v:shell_error != 0 || last_chat == ""
        return ""
    endi

    return $"{a:chats_dir}/{last_chat}"
endf

function! s:last_chat_exists(chats_dir)
    return a:chats_dir->ai#get_last_chat_path()->filereadable()
endf

function! s:new_chat_path(chats_dir)
    let chat_path = $"{a:chats_dir}/ai-chat-{localtime()}.md"

    if exists("g:i_am_in_a_test")
        " need to randomize the path for tests since they run in too quick
        " succession causing tests to fail when in reality this will never
        " need to run in such quick succession
        let chat_path .= $".{rand(srand()) % 1000000}.test"
    endi

    return chat_path
endf

function! s:open_chat(chat_path, mods = "")

    let open_chat = s:get_open_chat_winnr()

    if open_chat
        execute $"{open_chat}wincmd w"
        execute $"{a:mods} silent! edit {a:chat_path}"
    else
        execute $"{a:mods} split {a:chat_path}"
    endi

    return bufnr()
endf

function! s:get_open_chat_winnr()

    let wincount = winnr('$')
    for win in range(1, wincount)
        let bufnr = winbufnr(win)
        if bufnr == -1
            continue
        endi

        let fname = bufname(bufnr)
        if fname =~# 'ai.nvim/chats/ai-chat-\d\+\.md'
            return win
        endif
    endfo

    return 0
endf

function! s:check_prompt_for_model(prompt)
    let model = get(split(a:prompt), 0, "")

    if index(providers#get_models(), model) != -1
        return model
    endi

    return ""
endf

function! ai#completion(arglead, cmdline, curpos)
    let arg_count = a:cmdline->split()->len()

    if arg_count == 1
        return providers#get_models()->join("\n")
    endi

    return ""
endf
