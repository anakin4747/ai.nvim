require("plenary.busted")

describe(":Ai command", function()

    it("opens a new horizontal window", function()
        local wins_before = vim.api.nvim_list_wins()
        local height_before = vim.api.nvim_win_get_height(0)

        vim.cmd('Ai')

        local wins_after = vim.api.nvim_list_wins()
        local height_after = vim.api.nvim_win_get_height(0)

        assert(#wins_before == #wins_after -1)
        assert(height_after < height_before, "Expected a horizontal split")
    end)

    it("creates a new buffer", function()
        local bufs_before = vim.api.nvim_list_bufs()

        vim.cmd('Ai')

        local bufs_after = vim.api.nvim_list_bufs()

        assert(#bufs_before == #bufs_after -1)
    end)

end)
