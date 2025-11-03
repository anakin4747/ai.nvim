
function! providers#get()
    return globpath(&rtp, 'autoload/providers/*.vim', 1)
        \ ->split()
        \ ->sort()
        \ ->uniq()
        \ ->map({
        \     _, v -> substitute(v, '.*/providers/\(.*\)\.vim', '\1', '')
        \ })
endf

function! providers#get_models(provider = g:ai_provider)
    return call($"providers#{a:provider}#get_models", [])
endf
