
function! providers#get()
    return globpath(&rtp, 'autoload/providers/*.vim', 1)
        \ ->split()
        \ ->sort()
        \ ->uniq()
        \ ->map({
        \     _, v -> substitute(v, '.*/providers/\(.*\)\.vim', '\1', '')
        \ })
endf

function! providers#get_all_models()
    let models = []
    for provider in providers#get()
        let models += call($"providers#{provider}#get_models", [])
    endfo
    return models
endf
