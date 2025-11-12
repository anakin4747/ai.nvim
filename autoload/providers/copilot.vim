
function! providers#copilot#get_models()
    return s:get_models_response().data
        \ ->copy()
        \ ->filter({_, v -> v.model_picker_enabled})
        \ ->map({_, v -> v.id})
        \ ->sort()
endf

function! s:get_models_response()
    let json_path = $"{ai#nvim_get_dir()}/providers/copilot/models.json"
    return json_path->readfile()->join("\n")->json_decode()
endf


" naming is now inconsistent about the two different keys
function! providers#copilot#get_token(localtime = localtime())
    let token_json_path = $"{ai#get_cache_dir()}/providers/copilot/token.json"
    let token_json = token_json_path->readfile()->join("\n")->json_decode()

    if token_json.expires_at > a:localtime
        return token_json.token
    endi

    call s:save_remote_token()
    return providers#copilot#get_token(a:localtime)
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

    let remote_token_json = system(cmd)->trim()->json_decode()
    return remote_token_json
endf

function! s:save_remote_token()
    let token_json_path = $"{ai#get_cache_dir()}/providers/copilot/token.json"
    let json = [s:get_remote_token()->json_encode()]
    return json->writefile(token_json_path)
endf
