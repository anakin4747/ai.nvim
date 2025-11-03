
function! providers#get()
    return globpath(&rtp, 'autoload/providers/*.vim', 1)
        \ ->split()
        \ ->sort()
        \ ->uniq()
        \ ->map({
        \     _, v -> substitute(v, '.*/providers/\(.*\)\.vim', '\1', '')
        \ })
endf
