
function! ai#chat(mods = "", prompt = "")
    execute $"{a:mods} split"
    enew
endf
