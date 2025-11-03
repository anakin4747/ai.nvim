
let g:ai_provider = ""

command!
    \ -complete=custom,ai#completion
    \ -nargs=*
    \ -range
    \ -bang
    \ Ai
    \ call ai#main("<bang>", <range>, <line1>, <line2>, "<mods>", "<args>")
