#!/bin/bash

get_local_token() (
    jq -r '.[].oauth_token' ~/.config/github-copilot/apps.json
)

curl_token() (
    curl \
        --request "GET" \
        --url "https://api.github.com/copilot_internal/v2/token" \
        --header "authorization: Bearer $(get_local_token)" \
        --header "accept: application/json"
)

get_session_token() (
    curl_token | jq -r .token
)

curl_models() (
    curl \
        --request "GET" \
        --url "https://api.business.githubcopilot.com/models" \
        --header "authorization: Bearer $(get_session_token)" \
        --header "accept: application/json" \
        --header "content-type: application/json" \
        --header "copilot-integration-id: vscode-chat" \
        --header "editor-version: neovim/0.11.0"
)

curl_chat() (
    data='{ "temperature": 0.1, "n": 1, "messages": [ { "role": "system", "content": "give me code" }, { "role": "user", "content": "write me hello world in rust" } ], "max_tokens": 16384, "stream": true, "top_p": 1, "model": "gpt-4.1" }'
    curl \
        --request "POST" \
        --url "https://api.business.githubcopilot.com/chat/completions" \
        --header "authorization: Bearer $(get_session_token)" \
        --header "accept: application/json" \
        --header "content-type: application/json" \
        --header "copilot-integration-id: vscode-chat" \
        --header "editor-version: neovim/0.11.0" \
        --header "content-length: ${#data}" \
        --data "${data}"
)

parse_chat() (
    awk '{
        gsub(/^"/, "", $0)
        gsub(/"$/, "", $0)
        gsub(/\\"/, "\"", $0)
        printf("%s", $0)
    }' | sed 's/\\n/\n/g'
)

PS3="curl what? "
select _ in "token" "models" "chat"; do
    case $REPLY in
        1) curl_token | jq; break ;;
        2) curl_models | jq; break ;;
        3)
            echo
            curl_chat \
                | sed 's/data: //' \
                | grep -v DONE \
                | jq .choices[].delta.content \
                | grep -v '^null$' \
                | parse_chat
            echo
            break ;;
        *) ;;
    esac
done
