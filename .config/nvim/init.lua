-- ========================================================================= --
-- ==                           EDITOR SETTINGS                            == --
-- ========================================================================== --

-- Learn more about Neovim lua api
-- https://neovim.io/doc/user/lua-guide.html
-- https://vonheikemen.github.io/devlog/tools/build-your-first-lua-config-for-neovim/

vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.signcolumn = 'yes'

-- Space as leader key
vim.g.mapleader = ' '

-- Shortcuts
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>h', '^')
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>l', 'g_')
vim.keymap.set('n', '<leader>a', ':keepjumps normal! ggVG<cr>')

-- Basic clipboard interaction
vim.keymap.set({ 'n', 'x', 'o' }, 'gy', '"+y', { desc = 'Copy to clipboard' })
vim.keymap.set({ 'n', 'x', 'o' }, 'gp', '"+p', { desc = 'Paste clipboard content' })

local is_unix = vim.fn.has('unix') == 1 or vim.fn.has('mac') == 1

-- ========================================================================== --
-- ==                               PLUGINS                                == --
-- ========================================================================== --

local lazy = {}

function lazy.install(path)
	if not vim.loop.fs_stat(path) then
		print('Installing lazy.nvim....')
		vim.fn.system({
			'git',
			'clone',
			'--filter=blob:none',
			'https://github.com/folke/lazy.nvim.git',
			'--branch=stable', -- latest stable release
			path,
		})
	end
end

function lazy.setup(plugins)
	if vim.g.plugins_ready then
		return
	end

	-- You can "comment out" the line below after lazy.nvim is installed
	lazy.install(lazy.path)

	vim.opt.rtp:prepend(lazy.path)

	require('lazy').setup(plugins, lazy.opts)
	vim.g.plugins_ready = true
end

lazy.path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
lazy.opts = {}

-- Learn more about lazy.nvim
-- https://dev.to/vonheikemen/lazynvim-plugin-configuration-3opi
lazy.setup({
	{ 'Mofiqul/vscode.nvim' },
	{ 'folke/which-key.nvim' },
	{ 'nvim-lualine/lualine.nvim' },
	{ 'nvim-lua/plenary.nvim' },
	{ 'nvim-treesitter/nvim-treesitter' },
	{
		'nvim-telescope/telescope.nvim',
		config = function()
			require 'telescope'.setup {
				extensions = {
					fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true, case_mode = 'smart_case' },
					['ui-select'] = { require 'telescope.themes'.get_dropdown() }
				},
				vimgrep_argument = { 'rg', '--smart-case' }
			}
			require 'telescope'.load_extension 'ui-select'
		end,
		dependencies = {
			'nvim-lua/plenary.nvim',
			{
				'nvim-telescope/telescope-fzf-native.nvim',
				build = 'make'
			},
			'nvim-telescope/telescope-ui-select.nvim'
		},
		ft = 'mason',
		keys = {
			{ '<C-f>', function() require 'telescope.builtin'.live_grep() end },
			{ '<C-q>', function() require 'telescope.builtin'.quickfix() end }
		}
	},
	{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
	{ 'echasnovski/mini.nvim',                    branch = 'stable' },

	--mason
	{
		-- LSP Configuration & Plugins
		'neovim/nvim-lspconfig',
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			'williamboman/mason.nvim',
			'williamboman/mason-lspconfig.nvim',

			-- Useful status updates for LSP
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ 'j-hui/fidget.nvim', opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			'folke/neodev.nvim',
		},
	},


	{ 'VonHeikemen/lsp-zero.nvim', branch = 'v3.x' },
	{ 'neovim/nvim-lspconfig' },
	{ 'hrsh7th/nvim-cmp',          dependencies = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' } },

	-- code manipulation
	{ 'numToStr/Comment.nvim' },
	{ 'tpope/vim-surround' },
	{ 'wellle/targets.vim' },
	{ 'tpope/vim-repeat' },
	{ 'm4xshen/autoclose.nvim' },


	--utils
	{ 'akinsho/toggleterm.nvim' },
	{ 'ThePrimeagen/vim-be-good' },
})


-- ========================================================================== --
-- ==                         PLUGIN CONFIGURATION                         == --
-- ========================================================================== --

vim.cmd.colorscheme('vscode')

vim.g.netrw_banner = 0
vim.g.netrw_winsize = 30

-- See :help netrw-browse-maps
vim.keymap.set('n', '<leader>e', '<cmd>Lexplore<cr>', { desc = 'Toggle file explorer' })
vim.keymap.set('n', '<leader>E', '<cmd>Lexplore %:p:h<cr>', { desc = 'Open file explorer in current file' })

-- See :help lualine.txt
require('lualine').setup({
	options = {
		theme = 'tokyonight',
		icons_enabled = false,
		component_separators = '|',
		section_separators = '',
	},
})

-- See :help nvim-treesitter-modules
require('nvim-treesitter.configs').setup({
	highlight = { enable = true, },
	auto_install = true,
	ensure_installed = { 'lua', 'vim', 'vimdoc', 'json' },
})

-- See :help which-key.nvim-which-key-configuration
require('which-key').setup({})
require('which-key').register({
	['<leader>f'] = { name = 'Fuzzy Find', _ = 'which_key_ignore' },
	['<leader>b'] = { name = 'Buffer', _ = 'which_key_ignore' },
})

---
-- Comment.nvim
---
require('Comment').setup({})

require("autoclose").setup()

-- See :help MiniAi-textobject-builtin
require('mini.ai').setup({ n_lines = 500 })

-- See :help MiniComment.config
require('mini.comment').setup({})

-- See :help MiniSurround.config
require('mini.surround').setup({})

-- See :help MiniBufremove.config
require('mini.bufremove').setup({})

-- Close buffer and preserve window layout
vim.keymap.set('n', '<leader>bc', '<cmd>lua pcall(MiniBufremove.delete)<cr>', { desc = 'Close buffer' })

-- See :help telescope.builtin
vim.keymap.set('n', '<leader>?', '<cmd>Telescope oldfiles<cr>', { desc = 'Search file history' })
vim.keymap.set('n', '<leader><space>', '<cmd>Telescope buffers<cr>', { desc = 'Search open files' })
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Search all files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { desc = 'Search in project' })
vim.keymap.set('n', '<leader>fd', '<cmd>Telescope diagnostics<cr>', { desc = 'Search diagnostics' })
vim.keymap.set('n', '<leader>fs', '<cmd>Telescope current_buffer_fuzzy_find<cr>', { desc = 'Buffer local search' })

if is_unix then
	require('telescope').load_extension('fzf')
end

local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
	-- see :help lsp-zero-keybindings
	-- to learn the available actions
	lsp_zero.default_keymaps({ buffer = bufnr })
	lsp_zero.buffer_autoformat()
end)

-- to learn how to use mason.nvim
-- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guide/integrate-with-mason-nvim.md
require('mason').setup({})
require('mason-lspconfig').setup({
	ensure_installed = {},
	handlers = {
		function(server_name)
			require('lspconfig')[server_name].setup({})
		end,
	},
})

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local cmp = require('cmp')
local cmp_format = require('lsp-zero').cmp_format({ details = true })
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
	sources = {
		{ name = 'nvim_lsp' },
		{ name = "luasnip" },
		{ name = 'buffer' },
	},
	mapping = cmp.mapping.preset.insert({
		['<CR>'] = cmp.mapping.confirm({ select = false }),
		['<Tab>'] = cmp_action.luasnip_supertab(),
		['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
		['<C-Space>'] = cmp.mapping.complete(),
	}),

	--- (Optional) Show source name in completion menu
	formatting = cmp_format,
})

-- friendly snippets
require("luasnip/loaders/from_vscode").lazy_load()

---
-- toggleterm
---
-- See :help toggleterm-roadmap
require('toggleterm').setup({
	open_mapping = '<C-g>',
	direction = 'horizontal',
	shade_terminals = true
})


