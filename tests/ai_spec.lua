require("plenary.busted")

local this_repo = vim.fn.expand('<sfile>:p:h')
local default_mock_dir = this_repo .. "/tests/fixtures/ai.nvim"

local function fixture_dir(test_name)
    return this_repo .. "/tests/fixtures/" .. test_name .. "/ai.nvim"
end

local function readjsonfile(path)
    local stat = vim.uv.fs_stat(path)
    local fd = vim.uv.fs_open(path, "r", tonumber('444', 8))
    local data = vim.uv.fs_read(fd, stat.size):gsub("%z", "")
    vim.uv.fs_close(fd)
    return data
end

vim.g.ai_dir = default_mock_dir

vim.g.ai_localtime = 1763098419

vim.g.copilot_curl_token_mock = nil
vim.g.copilot_curl_models_mock = nil

local function teardown()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    vim.cmd("silent! only")

    vim.g.i_am_in_a_test = true

    vim.system({ "git", "clean", "-fq", vim.g.ai_dir, default_mock_dir }):wait()
    vim.system({ "git", "restore", vim.g.ai_dir, default_mock_dir }):wait()
    vim.g.ai_dir = default_mock_dir
    vim.g.copilot_curl_token_mock = nil
    vim.g.copilot_curl_models_mock = nil
end

describe(":Ai", function()

    after_each(teardown)

    it("does not error", function()
        assert.has_no.errors(function()
            vim.cmd('Ai')
        end)
    end)

    it("reuses the last chat name", function()
        vim.cmd('Ai')
        local expected = vim.api.nvim_buf_get_name(0)

        vim.cmd('Ai')
        local actual = vim.api.nvim_buf_get_name(0)

        assert.equal(expected, actual)
    end)

    it("reuses the last chat window", function()
        vim.cmd("Ai")
        local expected = vim.api.nvim_get_current_win()

        vim.cmd("Ai")
        local actual = vim.api.nvim_get_current_win()

        assert.are.same(expected, actual)
    end)

    it("puts the cursor at the bottom of the chat", function()
        vim.cmd("Ai")

        local expected = vim.api.nvim_buf_line_count(0)
        local actual = vim.api.nvim_win_get_cursor(0)[1]
        assert.are.same(expected, actual)
    end)
end)

describe(":Ai!", function()

    after_each(teardown)

    it("does not error", function()
        assert.has_no.errors(function()
            vim.cmd('Ai!')
        end)
    end)

    it("creates a new empty chat", function()
        vim.cmd('Ai')
        local old_name = vim.api.nvim_buf_get_name(0)

        vim.cmd('Ai!')
        local new_name = vim.api.nvim_buf_get_name(0)

        assert.not_equal(old_name, new_name)

        local expected = { '# ME', '' }
        local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same(expected, actual)
    end)

    it("reuses the last chat window", function()
        vim.cmd("Ai")
        local expected = vim.api.nvim_get_current_win()

        vim.cmd("Ai!")
        local actual = vim.api.nvim_get_current_win()

        assert.are.same(expected, actual)
    end)

    it("puts the cursor at the bottom of the chat", function()
        vim.cmd("Ai!")

        local expected = vim.api.nvim_buf_line_count(0)
        local actual = vim.api.nvim_win_get_cursor(0)[1]
        assert.are.same(expected, actual)
    end)
end)

describe(":Ai <prompt>", function()

    after_each(teardown)

    it("accepts a prompt as an argument", function()
        assert.has_no.errors(function()
            vim.cmd('Ai make me toast')
        end)
    end)

    it("passes <prompt> to the buffer", function()
        vim.cmd('Ai make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "make me toast"))
    end)
end)

describe(":Ai! <prompt>", function()

    after_each(teardown)

    it("accepts a prompt as an argument", function()
        assert.has_no.errors(function()
            vim.cmd('Ai! make me toast')
        end)
    end)

    it("passes <prompt> to the buffer", function()
        vim.cmd('Ai! make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "make me toast"))
    end)
end)

describe(":Ai <tab>", function()

    after_each(teardown)

    it("completes the first argument with models", function()
        local completion = vim.fn['ai#completion']("", "Ai ", "")

        assert(vim.tbl_contains(vim.split(completion, "\n"), "gemini-2.5-pro"))
    end)
end)

describe(":Ai <model>", function()

    after_each(teardown)

    it("sets the model to <model>", function()

        vim.cmd('Ai claude-haiku-4.5')

        assert(vim.g.ai_model, "claude-haiku-4.5")
    end)

    it("does not go to a chat", function()
        local expected_buf = vim.api.nvim_get_current_buf()
        local expected_win = vim.api.nvim_get_current_win()
        vim.cmd('Ai claude-haiku-4.5')
        local actual_buf = vim.api.nvim_get_current_buf()
        local actual_win = vim.api.nvim_get_current_win()

        assert.are.same(expected_buf, actual_buf)
        assert.are.same(expected_win, actual_win)
    end)

    describe("<prompt>", function()
        it("does not pass <model> to the chat", function()

            vim.cmd('Ai claude-haiku-4.5 sample chat')

            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

            assert.are.same({
                "# ME",
                "",
                "sample chat"
            }, lines)
        end)
    end)

    it("<tab> does not complete after first argument", function()
        local completion = vim.fn['ai#completion']("", "Ai dummy ", "")

        assert.same("", completion)
    end)
end)

describe(":'<,'>Ai", function()

    after_each(teardown)

    it("accepts a range without error", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c", "d" })

        assert.has_no.errors(function()
            vim.cmd('1,3Ai')
        end)
    end)

    it("passes the selected range to the buffer", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "De La Soul",
            "Wu-Tang",
            "C-Murder",
            "A Tribe Called Quest",
        })

        vim.cmd('2,3Ai')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "Wu-Tang"))
        assert(vim.tbl_contains(lines, "C-Murder"))
    end)

    it("<prompt> passes the selected range and <prompt> to the buffer", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "De La Soul",
            "Wu-Tang",
            "C-Murder",
            "A Tribe Called Quest",
        })

        vim.cmd('2,3Ai make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "Wu-Tang"))
        assert(vim.tbl_contains(lines, "C-Murder"))
        assert(vim.tbl_contains(lines, "make me toast"))
    end)

    it("wraps ranges in codeblocks if filetype is set", function()
        vim.cmd('edit /tmp/test.lua')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
        })
        vim.bo.filetype = "lua"

        vim.cmd('1,3Ai')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```lua",
            "line 1",
            "line 2",
            "line 3",
            "```"
        }, lines)
    end)

    it("wraps ranges in codeblocks", function()
        vim.cmd('edit /tmp/test')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
        })
        vim.bo.filetype = ""

        vim.cmd('1,3Ai')

        local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```",
            "line 1",
            "line 2",
            "line 3",
            "```"
        }, actual)
    end)

    it("works for single line ranges", function()
        vim.cmd('edit /tmp/test')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
        })

        vim.cmd('2Ai')

        local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```",
            "line 2",
            "```"
        }, actual)
    end)
end)

describe(":vert Ai", function()

    after_each(teardown)

    it("accepts a prompt as an argument with a vertical prefix", function()
        assert.has_no.errors(function()
            vim.cmd('vertical Ai make me toast')
        end)
    end)
end)

describe("ai#nvim_get_dir()", function()

    after_each(teardown)

    it("returns a normal ai.nvim directory", function()
        vim.g.i_am_in_a_test = nil

        local actual = vim.fn['ai#nvim_get_dir']()
        assert.are_match('.local/state', actual)
    end)

    it("returns the default mock directory under test", function()
        local actual = vim.fn['ai#nvim_get_dir']()
        assert.equal(default_mock_dir, actual)
    end)

    it("returns a specific mock directory under test if specified", function()
        vim.g.ai_dir = this_repo .. "/tests/fixtures/specific-test-case/ai.nvim"
        local actual = vim.fn['ai#nvim_get_dir']()
        assert.equal(vim.g.ai_dir, actual)
    end)
end)

describe("providers#get()", function()

    after_each(teardown)

    it("returns a list of providers", function()
        local expected = { "copilot" }
        local actual = vim.fn['providers#get']()
        assert.same(expected, actual)
    end)
end)

describe("providers#get_models()", function()

    after_each(teardown)

    it("returns all models for all providers", function()
        local expected = {
            'claude-haiku-4.5',
            'claude-sonnet-4.5',
            'gemini-2.5-pro',
            'gpt-4.1',
            'gpt-4o',
            'gpt-5',
            'gpt-5-codex',
            'gpt-5-mini',
        }

        local actual = vim.fn['providers#get_models']()

        assert.same(expected, actual)
    end)
end)

describe(":Ai gpt-4.1 <prompt>", function()

    after_each(teardown)

    it("gets cached token if token is not expired on submit", function()
        vim.g.ai_dir = fixture_dir("non-expired-remote-token")
        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        local old_token_json = readjsonfile(token_path)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_token_json = readjsonfile(token_path)
        assert.are.same(old_token_json, new_token_json)
    end)

    it("gets a new token if token is expired on submit", function()
        vim.g.ai_dir = fixture_dir("expired-remote-token")
        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        local old_token_json = readjsonfile(token_path)

        local new_token_fixture = default_mock_dir .. "/providers/copilot/token.json"
        vim.g.copilot_curl_token_mock = readjsonfile(new_token_fixture)

        -- mock curling of models
        local new_models_fixture = default_mock_dir .. "/providers/copilot/models.json"
        vim.g.copilot_curl_models_mock = readjsonfile(new_models_fixture)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_token_json = readjsonfile(token_path)
        assert.are.not_same(old_token_json, new_token_json)
        assert.are.same(
            vim.json.decode(vim.g.copilot_curl_token_mock),
            vim.json.decode(new_token_json)
        )
    end)

    it("gets a new token if no token exists on submit", function()
        vim.g.ai_dir = fixture_dir("no-token")

        local new_token_fixture = default_mock_dir .. "/providers/copilot/token.json"
        vim.g.copilot_curl_token_mock = readjsonfile(new_token_fixture)

        -- mock curling of models
        local new_models_fixture = default_mock_dir .. "/providers/copilot/models.json"
        vim.g.copilot_curl_models_mock = readjsonfile(new_models_fixture)

        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"

        assert(vim.fn.filereadable(token_path) == 0)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        assert(vim.fn.filereadable(token_path) == 1)

        local new_token_json = readjsonfile(token_path)

        assert.has_no.errors(function()
            vim.json.decode(new_token_json)
        end)

        assert.are.same(
            vim.json.decode(vim.g.copilot_curl_token_mock),
            vim.json.decode(new_token_json)
        )
    end)

    it("gets new models if token is expired on submit", function()
        vim.g.ai_dir = fixture_dir("expired-remote-token-get-models")

        -- mock curling of token
        vim.g.copilot_curl_token_mock = readjsonfile(
            default_mock_dir .. "/providers/copilot/token.json"
        )

        -- mock curling of models
        local new_models_fixture = default_mock_dir .. "/providers/copilot/models.json"
        vim.g.copilot_curl_models_mock = readjsonfile(new_models_fixture)

        local models_path = vim.g.ai_dir .. "/providers/copilot/models.json"
        local old_models_mtime = vim.uv.fs_stat(models_path).mtime

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_models_mtime = vim.uv.fs_stat(models_path).mtime
        assert.are.not_same(old_models_mtime, new_models_mtime)
    end)

    it("gets new models if no token exists on submit", function()
        vim.g.ai_dir = fixture_dir("no-token-get-models")

        -- mock curling of token
        vim.g.copilot_curl_token_mock = readjsonfile(
            default_mock_dir .. "/providers/copilot/token.json"
        )

        -- mock curling of models
        local new_models_fixture = default_mock_dir .. "/providers/copilot/models.json"
        vim.g.copilot_curl_models_mock = readjsonfile(new_models_fixture)

        local models_path = vim.g.ai_dir .. "/providers/copilot/models.json"
        local old_models_mtime = vim.uv.fs_stat(models_path).mtime

        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        assert(vim.fn.filereadable(token_path) == 0)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_models_mtime = vim.uv.fs_stat(models_path).mtime
        assert.are.not_same(old_models_mtime, new_models_mtime)
    end)

    it("gets new models if no models exist on submit", function()
        vim.g.ai_dir = fixture_dir("no-models")

        -- mock curling of models
        local new_models_fixture = default_mock_dir .. "/providers/copilot/models.json"
        vim.g.copilot_curl_models_mock = readjsonfile(new_models_fixture)

        -- ensure models.json does not exist
        local models_path = vim.g.ai_dir .. "/providers/copilot/models.json"
        assert(vim.fn.filereadable(models_path) == 0)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        assert(vim.fn.filereadable(models_path) == 1)

        local new_models_json = readjsonfile(models_path)

        assert.has_no.errors(function()
            vim.json.decode(new_models_json)
        end)

        assert.are.same(
            vim.json.decode(vim.g.copilot_curl_models_mock),
            vim.json.decode(new_models_json)
        )
    end)
end)
