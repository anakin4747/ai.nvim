
function! providers#copilot#submit_chat()
    call providers#copilot#get_token()
endf

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
function! providers#copilot#get_token(localtime = g:ai_localtime)
    let token_json_path = $"{ai#nvim_get_dir()}/providers/copilot/token.json"
    let token_json = token_json_path->readfile()->join("\n")->json_decode()

    if token_json.expires_at > a:localtime
        return token_json.token
    endi

    call s:save_remote_token()
    return providers#copilot#get_token(a:localtime)
endf

function! s:get_local_token()
    let apps_json_path = $"{ai#get_home_dir()}/.config/github-copilot/apps.json"
    let apps_json = apps_json_path->readfile()->join("\n")->json_decode()
    let top_dict = keys(apps_json)[0]
    return apps_json[top_dict]['oauth_token']
endf

function! s:get_remote_token()
    let copilot_url = "https://api.github.com/copilot_internal/v2/token"
    let local_token = s:get_local_token()

    let headers = $"
        \   --header 'Authorization: Bearer {local_token}'
        \   --header 'Accept: application/json'
        \"

    let remote_token_json = ai#curl(copilot_url, "GET", headers)->trim()->json_decode()
    return remote_token_json
endf

function! s:save_remote_token()
    let token_json_path = $"{ai#nvim_get_dir()}/providers/copilot/token.json"
    let json = [s:get_remote_token()->json_encode()]
    return json->writefile(token_json_path)
endf
