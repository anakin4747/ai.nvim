
let g:ai_model = ""

command!
    \ -complete=custom,ai#completion
    \ -nargs=*
    \ -range
    \ -bang
    \ Ai
    \ call ai#main("<bang>", <range>, <line1>, <line2>, "<mods>", "<args>")
