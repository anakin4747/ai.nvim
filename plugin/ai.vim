
let g:ai_model = ""
"let g:ai_dir = ""
"let g:ai_home_dir = ""
let g:ai_localtime = localtime()

command!
    \ -complete=custom,ai#completion
    \ -nargs=*
    \ -range
    \ -bang
    \ Ai
    \ call ai#main("<bang>", <range>, <line1>, <line2>, "<mods>", "<args>")
