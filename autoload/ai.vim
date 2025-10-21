
function! ai#main(bang, line1, line2, mods = "", prompt = "") abort

    if exists("g:i_am_in_a_test")
        let chat_cache_dir = $"{stdpath("run")}/ai.nvim/chats"
        let chat_path = $"{chat_cache_dir}/ai-chat-{rand(srand()) % 1000000}.md"
    else
        let chat_cache_dir = $"{stdpath("cache")}/ai.nvim/chats"
        let chat_path = $"{chat_cache_dir}/ai-chat-{localtime()}.md"
    endi

    call mkdir(chat_cache_dir, "p")

    let original_buf = bufnr()

    let bufnr = s:open_chat(chat_path, a:mods)

    if a:prompt != ""
        call appendbufline(bufnr, "$", a:prompt)
    endi

    if a:line1 != a:line2
        let lines = getbufline(original_buf, a:line1, a:line2)
        call appendbufline(bufnr, "$", lines)
    endi

endf

function! s:open_chat(chat_path, mods = "")
    execute $"{a:mods} split"

    execute $"edit {a:chat_path}"

    return bufnr()
endf
