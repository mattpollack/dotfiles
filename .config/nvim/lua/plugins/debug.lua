return {
  { "nvim-neotest/nvim-nio" },
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim'
    },
    config = function()
      local dap = require('dap')
      require('dapui').setup()

      dap.adapters.godot = {
        type = 'server',
        host = '127.0.0.1',
        port = 6006
      }

      dap.configurations.gdscript = {
        {
          type = 'godot',
          request = 'launch',
          name = 'Launch scene',
          project = '${workspaceFolder}',
          launch_scene = true
        }
      }
    end
  }
}