
function! providers#copilot#submit_chat()
    call s:get_token()
endf

function! providers#copilot#get_models()
    return s:get_models().data
        \ ->copy()
        \ ->filter({_, v -> v.model_picker_enabled})
        \ ->map({_, v -> v.id})
        \ ->sort()
endf

function! s:get_models()
    let models_json_path = $"{ai#nvim_get_dir()}/providers/copilot/models.json"

    if !filereadable(models_json_path)
        call s:save_models()
    endi

    return models_json_path->readfile()->join("\n")->json_decode()
endf

function! s:save_models()
    let models_json_path = $"{ai#nvim_get_dir()}/providers/copilot/models.json"
    let json = [s:curl_models()->json_encode()]
    return json->writefile(models_json_path)
endf

function! s:curl_models()
    if exists("g:copilot_curl_models_mock")
        return g:copilot_curl_models_mock->trim()->json_decode()
    endi

    let copilot_url = "https://api.business.githubcopilot.com/models"
    let token = s:get_token()

    let headers = [
        \   $"authorization: Bearer {token}",
        \   $"accept: application/json",
        \   $"content-type: application/json",
        \   $"copilot-integration-id: vscode-chat",
        \   $"editor-version: neovim/0.11.0",
        \]

    return ai#curl(copilot_url, "GET", headers)->trim()->json_decode()
endf

function! s:get_token(localtime = g:ai_localtime)
    let token_json_path = $"{ai#nvim_get_dir()}/providers/copilot/token.json"

    if !filereadable(token_json_path)
        call s:save_remote_token()
        call s:save_models()
        return s:get_token(a:localtime)
    endi

    let token_json = token_json_path->readfile()->join("\n")->json_decode()

    if token_json.expires_at > a:localtime
        return token_json.token
    endi

    call s:save_remote_token()
    call s:save_models()
    return s:get_token(a:localtime)
endf

function! s:get_local_token()
    let apps_json_path = $"{expand("$HOME")}/.config/github-copilot/apps.json"
    let apps_json = apps_json_path->readfile()->join("\n")->json_decode()
    return keys(apps_json)[0]['oauth_token']
endf

function! s:curl_remote_token()
    if exists("g:copilot_curl_token_mock")
        return g:copilot_curl_token_mock->trim()->json_decode()
    endi

    let copilot_url = "https://api.github.com/copilot_internal/v2/token"
    let local_token = s:get_local_token()

    let headers = [
        \   $"authorization: Bearer {local_token}",
        \   $"accept: application/json",
        \]

    return ai#curl(copilot_url, "GET", headers)->trim()->json_decode()
endf

function! s:save_remote_token()
    let token_json_path = $"{ai#nvim_get_dir()}/providers/copilot/token.json"
    let json = [s:curl_remote_token()->json_encode()]
    return json->writefile(token_json_path)
endf
