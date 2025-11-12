
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


" naming is now inconsistent about the two different keys
function! providers#copilot#get_token(localtime = localtime())
    let token_json_path = $"{ai#get_cache_dir()}/providers/copilot/token.json"
    let token_json = token_json_path->readfile()->join("\n")->json_decode()

    if token_json.expires_at > a:localtime
        return token_json.token
    endi

    return "TODO: do network side of getting token"
endf

function! s:get_local_token()
    let apps_json_path = expand("$HOME/.config/github-copilot/apps.json")
    let apps_json = apps_json_path->readfile()->join("\n")->json_decode()
    let top_dict = keys(apps_json)[0]
    return apps_json[top_dict]['oauth_token']
endf

function! s:get_remote_token()

    let copilot_url = "https://api.github.com/copilot_internal/v2/token"
    let local_token = s:get_local_token()

    let cmd = $"
        \   curl
        \       --request GET
        \       --url '{copilot_url}'
        \       --header 'Authorization: Bearer {local_token}'
        \       --header 'Accept: application/json'
        \       --silent
        \"

    return system(cmd)->trim()
endf
