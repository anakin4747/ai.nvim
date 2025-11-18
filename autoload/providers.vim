
function! providers#get() abort
    return globpath(&rtp, 'autoload/providers/*.vim', 1)
        \ ->split()
        \ ->sort()
        \ ->uniq()
        \ ->map({
        \     _, v -> substitute(v, '.*/providers/\(.*\)\.vim', '\1', '')
        \ })
endf

function! providers#get_models() abort
    let models = []
    for provider in providers#get()
        let models += call($"providers#{provider}#get_models", [])
    endfo
    return models
endf

function! providers#get_provider_from_model(model = g:ai_model) abort
    for provider in providers#get()
        let models = call($"providers#{provider}#get_models", [])
        if index(models, a:model) != -1
            return provider
        endi
    endfo
    return ''
endf

function! providers#submit_chat(provider = providers#get_provider_from_model()) abort
    call call($"providers#{a:provider}#submit_chat", [])
endf
