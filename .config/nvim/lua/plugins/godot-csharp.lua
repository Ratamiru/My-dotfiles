return {
  -- OmniSharp for C# LSP (автодополнение, диагностика, go-to-definition)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          -- mason автоматически установит omnisharp
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = true,
            },
            RoslynExtensionsOptions = {
              EnableAnalyzersSupport = true,
              EnableImportCompletion = true,
            },
          },
        },
        -- GDScript LSP — подключается к встроенному LSP серверу Godot (порт 6005)
        gdscript = {
          cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
          root_dir = require("lspconfig.util").root_pattern("project.godot", ".git"),
        },
      },
      setup = {
        gdscript = function(_, opts)
          -- gdscript не устанавливается через mason, настраиваем вручную
          require("lspconfig").gdscript.setup(opts)
          return true
        end,
      },
    },
  },

  -- Mason: установить omnisharp и netcoredbg (дебаггер)
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "omnisharp",
        "netcoredbg",
      },
    },
  },

  -- Treesitter парсеры для C# и GDScript
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "c_sharp",
        "gdscript",
        "godot_resource",
      })
    end,
  },
}
