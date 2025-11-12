
function! providers#copilot#get_models()
    return s:get_models_response().data
        \ ->copy()
        \ ->filter({_, v -> v.model_picker_enabled})
        \ ->map({_, v -> v.id})
        \ ->sort()
endf

function! s:get_models_response()
    " TODO: replace test fixture with API call
    let json_path = $"{expand('<sfile>:p:h')}/tests/fixtures/copilot/get_models_response.json"
    return json_path->readfile()->join("\n")->json_decode()
endf

function! providers#copilot#get_token(localtime = localtime())
    let token_json_path = $"{ai#get_cache_dir()}/providers/copilot/token.json"
    let token_json = token_json_path->readfile()->join("\n")->json_decode()

    if token_json.expires_at > a:localtime
        return token_json.token
    endi

    return "TODO: do network side of getting token"
endf
