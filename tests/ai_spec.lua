require("plenary.busted")

local function teardown()
    local current_buf = vim.api.nvim_get_current_buf()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if bufnr ~= current_buf and vim.api.nvim_buf_is_loaded(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end
    vim.cmd("silent! only")
    vim.fn.delete(vim.fn['ai#get_chats_dir'](), 'rf')
end

describe(":Ai", function()

    after_each(teardown)

    it("<prompt> accepts a prompt as an argument", function()
        assert.has_no.errors(function()
            vim.cmd('Ai make me toast')
        end)
    end)

    it("<prompt> passes the prompt to the buffer", function()
        vim.cmd('Ai make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "make me toast"))
    end)

    it("reuses the last chat name", function()
        vim.cmd('Ai')
        local first_buf_name = vim.api.nvim_buf_get_name(0)

        vim.cmd('silent! write')

        vim.cmd('Ai')
        local second_buf_name = vim.api.nvim_buf_get_name(0)

        assert.equal(first_buf_name, second_buf_name)
    end)

    it("reuses the last chat window", function()
        vim.cmd("Ai")
        local expected = vim.api.nvim_get_current_win()

        vim.cmd("silent! write")

        vim.cmd("Ai")
        local actual = vim.api.nvim_get_current_win()

        assert.are.same(expected, actual)
    end)

    it("puts cursor at the bottom of the chat", function()
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

    it("creates a new chat", function()
        vim.cmd('Ai')
        local first_buf_name = vim.api.nvim_buf_get_name(0)

        vim.cmd('Ai!')
        local second_buf_name = vim.api.nvim_buf_get_name(0)

        assert.not_equal(first_buf_name, second_buf_name)
    end)

    it("reuses the last chat", function()
        vim.cmd("Ai")
        local expected = vim.api.nvim_get_current_win()

        vim.cmd("silent! write")

        vim.cmd("Ai!")
        local actual = vim.api.nvim_get_current_win()

        assert.are.same(expected, actual)
    end)

    it("creates an empty chat ", function()
        vim.cmd('Ai!')
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        assert.are.same(lines, { '# ME', '' })
    end)
end)

describe(":Ai! <model>", function()

    after_each(teardown)

    it("sets the model to <model>", function()

        vim.cmd('Ai! claude-haiku-4.5 sample chat')

        assert(vim.g.ai_model, "claude-haiku-4.5")
    end)

    it("does not pass <model> to the chat", function()

        vim.cmd('Ai! claude-haiku-4.5 sample chat')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "sample chat"
        }, lines)
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

    it("passes the selected range and arguments to the buffer", function()
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

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```",
            "line 1",
            "line 2",
            "line 3",
            "```"
        }, lines)
    end)

    it("works for single line ranges", function()
        vim.cmd('edit /tmp/test')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
        })

        vim.cmd('2Ai')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```",
            "line 2",
            "```"
        }, lines)
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

describe("providers#get", function()

    after_each(teardown)

    it("returns a list of providers", function()
        local expected = { "copilot" }
        local actual = vim.fn['providers#get']()
        assert.same(expected, actual)
    end)
end)

describe("providers#get_models", function()

    after_each(teardown)

    it("with copilot provider returns a list of provided models", function()
        vim.g.ai_provider = "copilot"

        local expected = {
            'claude-haiku-4.5',
            'claude-sonnet-4',
            'claude-sonnet-4.5',
            'gemini-2.5-pro',
            'gpt-4.1',
            'gpt-4o',
            'gpt-5',
            'gpt-5-mini',
        }

        local actual = vim.fn['providers#get_models']()

        assert.same(expected, actual)
    end)
end)

describe("providers#get_all_models", function()

    after_each(teardown)

    it("returns a list of all models for all providers", function()
        local expected = {
            'claude-haiku-4.5',
            'claude-sonnet-4',
            'claude-sonnet-4.5',
            'gemini-2.5-pro',
            'gpt-4.1',
            'gpt-4o',
            'gpt-5',
            'gpt-5-mini',
        }

        local actual = vim.fn['providers#get_all_models']()

        assert.same(expected, actual)
    end)
end)

describe("tab", function()

    after_each(teardown)

    it("completes models as first argument", function()
        local completion = vim.fn['ai#completion']("", "Ai ", "")

        assert(vim.tbl_contains(vim.split(completion, "\n"), "gemini-2.5-pro"))
    end)

    it("does not complete anything after first argument", function()
        local completion = vim.fn['ai#completion']("", "Ai dummy ", "")

        assert.same("", completion)
    end)
end)
