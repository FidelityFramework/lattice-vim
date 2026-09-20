-- Thin Clef registration over Neovim's standard LSP client.
-- Project interpretation and semantic facts belong to the configured CCS server.
local M = {}
local command
local clients = {}
local stopping_clients = false
local group = 'LatticeClef'

local function stop_clients()
  stopping_clients = true
  local stopping = {}
  for id in pairs(clients) do
    local client = vim.lsp.get_client_by_id(id)
    if client then
      table.insert(stopping, client)
      client:stop()
    end
  end
  clients = {}
  -- Reconfiguration must not leave two server generations publishing results.
  local function removed()
    for _, client in ipairs(stopping) do
      if vim.lsp.get_client_by_id(client.id) then return false end
    end
    return true
  end
  local finished = vim.wait(1000, removed, 10)
  if not finished then
    for _, client in ipairs(stopping) do
      if vim.lsp.get_client_by_id(client.id) then client:stop(true) end
    end
    finished = vim.wait(1000, removed, 10)
  end
  stopping_clients = false
  if not finished then
    command = nil
    error('The previous Lattice server did not stop; configure it again after it exits')
  end
end

local function project_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' or vim.bo[bufnr].buftype ~= '' then return nil end
  local manifests = vim.fs.find(function(file)
    return file:match('%.fidproj$') ~= nil
  end, { path = vim.fs.dirname(name), upward = true, type = 'file', limit = 1 })
  return manifests[1] and vim.fs.dirname(manifests[1]) or nil
end

local function attach(bufnr)
  if stopping_clients or not command or not vim.api.nvim_buf_is_loaded(bufnr) then return end
  local root = vim.bo[bufnr].filetype == 'clef' and project_root(bufnr) or nil

  -- A renamed buffer or changed filetype must not stay with its former root.
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if clients[client.id] and client.config.root_dir ~= root then
      vim.lsp.buf_detach_client(bufnr, client.id)
    end
  end
  if not root then return end

  local id = vim.lsp.start({
    name = 'lattice',
    cmd = vim.deepcopy(command),
    root_dir = root,
    get_language_id = function() return 'clef' end,
    on_exit = function(_, _, client_id) clients[client_id] = nil end,
  }, {
    bufnr = bufnr,
    reuse_client = function(client, config)
      return clients[client.id] == true and client.config.root_dir == config.root_dir
    end,
  })
  if id then clients[id] = true end
end

local function attach_open_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do attach(bufnr) end
end

--- Configure the explicit server argv; no server is downloaded or guessed.
--- Repeating setup with the same argv is safe and does not restart clients.
function M.setup(config)
  if vim.fn.has('nvim-0.11') ~= 1 then
    error('Lattice requires Neovim 0.11 or newer')
  end
  local cmd = type(config) == 'table' and config.cmd or nil
  if type(cmd) ~= 'table' or not vim.islist(cmd) or #cmd == 0 then
    error('Lattice requires an explicit cmd array containing the server executable and arguments')
  end
  for _, arg in ipairs(cmd) do
    if type(arg) ~= 'string' or arg == '' then
      error('Every Lattice cmd entry must be a non-empty string')
    end
  end
  if vim.fn.executable(cmd[1]) ~= 1 then
    error('Lattice server executable not found: ' .. cmd[1])
  end

  if not vim.deep_equal(command, cmd) then stop_clients() end
  command = vim.deepcopy(cmd)
  vim.api.nvim_create_augroup(group, { clear = true })
  vim.api.nvim_create_autocmd({ 'FileType', 'BufEnter', 'BufFilePost' }, {
    group = group,
    callback = function(event) attach(event.buf) end,
    desc = 'Attach Clef buffers to the explicitly configured Lattice server',
  })
  attach_open_buffers()
end

--- Stop this plugin's clients and disable automatic attachment until setup.
function M.stop()
  pcall(vim.api.nvim_del_augroup_by_name, group)
  command = nil
  stop_clients()
end

--- Restart with the same explicit command and current project roots.
function M.restart()
  if not command then error('Configure Lattice with setup({ cmd = ... }) before restarting') end
  stop_clients()
  attach_open_buffers()
end

return M
