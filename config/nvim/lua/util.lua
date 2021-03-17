
local M = {}

local scopes = {o = vim.o, b = vim.bo, w = vim.wo}

function M.opt(scope, key, value)
    scopes[scope][key] = value
    if scope ~= 'o' then scopes['o'][key] = value end
end

function M.map(mode, lhs, rhs, opts)
    local options = {noremap = true, silent = true}
    if opts then options = vim.tbl_extend('force', options, opts) end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function M.update(dst, src)
    local out = {}
    for k, v in pairs(dst) do
        out[k] = v
    end
    for k, v in pairs(src) do
        out[k] = v
    end
    return out
end

-- host-specific settings
M.host = {
    disable_lsp_fmt = {}
}

if vim.fn.hostname() == "bressonium" then
    M.host.disable_lsp_fmt = {
        clangd = true,
        pyls = true,
    }
end

return M
