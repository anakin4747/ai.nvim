
function! providers#copilot#get_models()
    return s:get_models_response().data
        \ ->copy()
        \ ->filter({_, v -> v.model_picker_enabled})
        \ ->map({_, v -> v.name})
        \ ->sort()
endf

function! s:get_models_response()
    " TODO: replace test fixture with API call
    let json_path = $"{expand('<sfile>:p:h')}/tests/fixtures/copilot/get_models_response.json"
    return json_path->readfile()->join("\n")->json_decode()
endf
