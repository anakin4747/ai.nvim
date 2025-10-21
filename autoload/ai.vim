
function! ai#main(mods = "", prompt = "", line1 = 0, line2 = 0)

    let original_buf = bufnr()

    let bufnr = s:open_chat(a:mods)

    call appendbufline(bufnr, "$", a:prompt)

    if a:line1 != 0 && a:line2 != 0
        let lines = getbufline(original_buf, a:line1, a:line2)
        call appendbufline(bufnr, "$", lines)
    endi

endf

function! s:open_chat(mods = "")
    execute $"{a:mods} split"
    enew
    return bufnr()
endf
