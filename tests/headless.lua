local repo = vim.fn.getcwd()
local temp = vim.fn.tempname() .. '-lattice project with spaces'
local root, nested = temp .. '/project', temp .. '/project/nested'
local log = temp .. '/transcript.jsonl'
vim.opt.runtimepath:prepend(repo)
vim.cmd('filetype plugin on')
vim.cmd('runtime! plugin/ionide.vim')
vim.o.hidden = true

local function check(condition, message)
  if not condition then error(message, 2) end
end
local function wait_for(message, predicate)
  check(vim.wait(5000, predicate, 10), 'Timed out: ' .. message)
end
local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end
local function transcript(method)
  local records = {}
  if vim.fn.filereadable(log) == 1 then
    for _, line in ipairs(vim.fn.readfile(log)) do
      local entry = vim.json.decode(line)
      if not method or entry.method == method then records[#records + 1] = entry end
    end
  end
  return records
end
local function open(path)
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end
local function attached(bufnr)
  return vim.lsp.get_clients({ bufnr = bufnr, name = 'lattice' })
end
local function client_for(bufnr)
  wait_for('initialized client for ' .. bufnr, function()
    local found = attached(bufnr)
    return #found == 1 and found[1].initialized
  end)
  return attached(bufnr)[1]
end

local lattice
local function run()
  write(root .. '/Main.fidproj', { 'This marker is deliberately not parsed by the client.' })
  write(root .. '/Other.fidproj', { 'Project membership remains a server decision.' })
  write(root .. '/main.clef', { 'bad' })
  write(root .. '/second.clef', { 'fixture second' })
  write(root .. '/existing.fs', { 'let fsharp = 1' })
  write(root .. '/existing.fsproj', { '<Project />' })
  write(root .. '/script.clefx', { 'fixture script' })
  write(nested .. '/Nested.fidproj', { 'nearest project marker' })
  write(nested .. '/nested.clef', { 'fixture nested' })
  write(temp .. '/outside.clef', { 'no project here' })
  vim.fn.mkdir(temp .. '/.git', 'p')

  local main = open(root .. '/main.clef')
  check(vim.bo[main].filetype == 'clef', '.clef must register as clef')
  check(#vim.lsp.get_clients() == 0, 'Plugin loading must not guess or launch a server')
  local fsharp = open(root .. '/existing.fs')
  open(root .. '/existing.fsproj')
  check(vim.fn.exists('g:loaded_autoload_fsharp') == 0, 'Retired F# entry points loaded FSAC callbacks')
  check(vim.fn.exists(':FsiEval') == 0, 'Retired FSI commands must not be installed')
  check(#vim.lsp.get_clients() == 0, 'F# files must not launch FSAC')

  lattice = require('lattice')
  for _, invalid in ipairs({ {}, { cmd = {} }, { cmd = 'server' }, { cmd = { false } },
    { cmd = { '/nonexistent/lattice-server' } } }) do
    check(not pcall(lattice.setup, invalid), 'Invalid/missing explicit command was accepted')
  end
  local argv = { vim.fn.exepath('node'), repo .. '/tests/fixture-server.mjs', log, 'argument with spaces' }
  lattice.setup({ cmd = argv })
  local first = client_for(main)
  check(first.config.root_dir == root, 'Incorrect .fidproj root')
  check(first:supports_method('textDocument/hover'), 'Negotiated hover is missing')
  check(not first:supports_method('textDocument/codeLens'), 'Unadvertised codeLens was invented')
  check(#attached(fsharp) == 0, 'Clef server attached to an F# buffer')
  wait_for('initial diagnostic', function() return #vim.diagnostic.get(main) == 1 end)
  local diagnostic = vim.diagnostic.get(main)[1]
  check(diagnostic.code == 'FIXTURE001' and diagnostic.lnum == 0 and diagnostic.col == 0,
    'Server diagnostic code/range not preserved')

  local hover
  first:request('textDocument/hover', {
    textDocument = { uri = vim.uri_from_bufnr(main) }, position = { line = 0, character = 0 },
  }, function(err, result) check(not err, 'Hover error'); hover = result end, main)
  wait_for('hover', function() return hover ~= nil end)
  check(hover.contents.value == 'fixture hover', 'Server hover not preserved')

  vim.api.nvim_buf_set_lines(main, 0, -1, false, { 'corrected é' })
  wait_for('full-text change and cleared diagnostic', function()
    return #transcript('textDocument/didChange') >= 1 and #vim.diagnostic.get(main) == 0
  end)
  local change = transcript('textDocument/didChange')[1].params
  check(change.contentChanges[1].text == 'corrected é\n', 'Full-text/Unicode content changed')
  check(change.contentChanges[1].range == nil, 'Full sync became a ranged change')
  check(change.textDocument.version > transcript('textDocument/didOpen')[1].params.textDocument.version,
    'Document version did not advance')

  local second = open(root .. '/second.clef')
  check(client_for(second).id == first.id, 'One project should reuse its client')
  local inner = open(nested .. '/nested.clef')
  local inner_client = client_for(inner)
  check(inner_client.id ~= first.id and inner_client.config.root_dir == nested,
    'Nearest nested .fidproj must have its own root/client')
  local outside = open(temp .. '/outside.clef')
  local script = open(root .. '/script.clefx')
  vim.cmd('enew')
  vim.bo.filetype = 'clef'
  local untitled = vim.api.nvim_get_current_buf()
  check(#attached(outside) == 0 and #attached(script) == 0 and #attached(untitled) == 0,
    'Unsupported/outside-project buffers must not attach')
  check(#vim.lsp.get_clients() == 2, 'Unexpected server process')

  lattice.setup({ cmd = argv })
  check(client_for(main).id == first.id, 'Repeated setup restarted an unchanged client')
  check(#vim.api.nvim_get_autocmds({ group = 'LatticeClef' }) == 3, 'Setup duplicated lifecycle hooks')
  check(not pcall(lattice.setup, { cmd = { '/missing/server' } }), 'Invalid reconfiguration accepted')
  check(client_for(main).id == first.id, 'Invalid configuration disrupted the running client')
  vim.api.nvim_set_current_buf(second)
  vim.cmd('file ' .. vim.fn.fnameescape(temp .. '/renamed.clef'))
  wait_for('renamed buffer detach', function() return #attached(second) == 0 end)
  wait_for('didClose after root change', function() return #transcript('textDocument/didClose') >= 1 end)

  lattice.restart()
  local restarted = client_for(main)
  client_for(inner)
  check(restarted.id ~= first.id and first:is_stopped(),
    'Restart did not replace the old client: old=' .. first.id .. ', new=' .. restarted.id
      .. ', stopped=' .. tostring(first:is_stopped()))
  check(#vim.lsp.get_clients() == 2, 'Restart left duplicate processes')
  local next_argv = vim.deepcopy(argv)
  next_argv[#next_argv] = 'new server argument'
  lattice.setup({ cmd = next_argv })
  check(client_for(main).id ~= restarted.id and restarted:is_stopped(), 'Changed command was not applied')
  client_for(inner)
  lattice.stop()
  check(#vim.lsp.get_clients() == 0, 'Stop left active clients')
  vim.api.nvim_set_current_buf(main)
  check(#attached(main) == 0, 'Stop left automatic attachment enabled')
  check(not pcall(lattice.restart), 'Restart without configuration should be explicit')
  lattice.setup({ cmd = argv })
  client_for(main)
  client_for(inner)
  lattice.stop()

  local per_process = {}
  for _, entry in ipairs(transcript()) do
    per_process[entry.pid] = per_process[entry.pid] or {}
    local state = per_process[entry.pid]
    if entry.event == 'start' then
      check(vim.deep_equal(entry.args, { 'argument with spaces' })
        or vim.deep_equal(entry.args, { 'new server argument' }), 'Command arguments were rewritten')
    elseif entry.event == 'terminated' then
      error('Responsive fixture was force-terminated')
    elseif entry.method then
      check(not entry.method:match('^fsharp/') and not entry.method:find('codeLens'),
        'Private FSAC or unsupported feature request: ' .. entry.method)
      if entry.method == 'initialize' then
        check(entry.params.rootUri == vim.uri_from_fname(root)
          or entry.params.rootUri == vim.uri_from_fname(nested), 'Wrong initialize rootUri')
        check(entry.params.initializationOptions == nil or entry.params.initializationOptions == vim.NIL,
          'FSAC initialization options leaked')
      elseif entry.method == 'textDocument/didOpen' then
        check(entry.params.textDocument.languageId == 'clef', 'Wrong LSP language ID')
      elseif entry.method == 'shutdown' then
        state.shutdown = true
      elseif entry.method == 'exit' then
        check(state.shutdown, 'exit preceded shutdown')
        state.exit = true
      end
    end
  end
  for _, state in pairs(per_process) do check(state.exit, 'A server did not receive graceful exit') end
  check(vim.fn.exists('g:loaded_autoload_fsharp') == 0, 'Clef integration activated FSAC code')
  print('PASS: Clef registration, explicit command, roots, LSP exchange, isolation and lifecycle')
end

local ok, failure = xpcall(run, debug.traceback)
if lattice then pcall(lattice.stop) end
if not ok then
  io.stderr:write(tostring(failure) .. '\nEvidence: ' .. temp .. '\n')
  vim.cmd('cquit 1')
else
  vim.fn.delete(temp, 'rf')
  vim.cmd('qa!')
end
