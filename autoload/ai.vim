
function! ai#main(bang, line1, line2, mods = "", prompt = "") abort

    let chats_dir = ai#get_chats_dir()

    if !isdirectory(chats_dir)
        call mkdir(chats_dir, "p")
    endi

    if a:bang == "!" || !s:last_chat_exists(chats_dir)
        let chat_path = s:new_chat_path(chats_dir)
    else
        let chat_path = s:get_last_chat_path(chats_dir)
    endi

    let original_buf = bufnr()
    let original_filetype = &filetype

    let bufnr = s:open_chat(chat_path, a:mods)

    if a:prompt != ""
        call appendbufline(bufnr, "$", a:prompt)
    endi

    if a:line1 != a:line2
        let lines = [$"```{original_filetype}"]
        let lines += getbufline(original_buf, a:line1, a:line2)
        let lines += ["```"]
        call appendbufline(bufnr, "$", lines)
    endi

endf

function! ai#get_chats_dir()
    if exists("g:i_am_in_a_test")
        return $"{stdpath("run")}/ai.nvim/chats"
    endi

    return $"{stdpath("cache")}/ai.nvim/chats"
endf

function! s:get_last_chat_path(chats_dir)
    let last_chat = system($"ls -1t {a:chats_dir} | head -n1")->trim()
    if v:shell_error != 0 || last_chat == ""
        return ""
    endi

    return $"{a:chats_dir}/{last_chat}"
endf

function! s:last_chat_exists(chats_dir)
    return a:chats_dir->s:get_last_chat_path()->filereadable()
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
    execute $"{a:mods} split {a:chat_path}"
    return bufnr()
endf
