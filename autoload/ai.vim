
function! ai#main(mods = "", prompt = "")
    let bufnr = s:open_chat(a:mods)
endf

function! s:open_chat(mods = "")
    execute $"{a:mods} split"
    enew
    return bufnr()
endf
