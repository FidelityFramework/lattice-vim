-- MLIR Navigation for Fidelity
-- Provides source linking between F# and generated MLIR

local M = {}

--- Parse MLIR loc() attributes from a file
--- loc("HelloWorld.fs":5:12) -> { file = "HelloWorld.fs", line = 5, col = 12 }
---@param mlir_file string Path to MLIR file
---@return table[] List of location mappings
local function parse_mlir_locations(mlir_file)
  local locations = {}
  local line_num = 0

  local f = io.open(mlir_file, "r")
  if not f then return locations end

  for line in f:lines() do
    line_num = line_num + 1
    -- Match: loc("file.fs":line:col)
    local file, src_line, src_col = line:match('loc%("([^"]+)":(%d+):(%d+)%)')
    if file then
      table.insert(locations, {
        mlir_line = line_num,
        src_file = file,
        src_line = tonumber(src_line),
        src_col = tonumber(src_col),
      })
    end
  end

  f:close()
  return locations
end

--- Find MLIR file for current F# project
---@return string|nil Path to MLIR file or nil
local function find_mlir_for_project()
  -- Look for .fidproj in current directory or parents
  local cwd = vim.fn.getcwd()
  local fidproj = vim.fn.glob(cwd .. '/*.fidproj')

  if fidproj ~= '' then
    -- Extract project name from first .fidproj found
    local name = vim.fn.fnamemodify(fidproj, ':t:r')
    local mlir_path = cwd .. '/target/intermediates/' .. name .. '.mlir'
    if vim.fn.filereadable(mlir_path) == 1 then
      return mlir_path
    end
  end

  -- Fallback: look for any .mlir in target/intermediates
  local mlir_glob = vim.fn.glob(cwd .. '/target/intermediates/*.mlir')
  if mlir_glob ~= '' then
    -- Return first match
    return vim.split(mlir_glob, '\n')[1]
  end

  return nil
end

--- Jump from F# source position to corresponding MLIR
function M.jump_to_mlir()
  local src_file = vim.fn.expand('%:t')  -- Current filename (tail only)
  local src_line = vim.fn.line('.')

  local mlir_file = find_mlir_for_project()
  if not mlir_file then
    vim.notify("No MLIR file found. Run Firefly with -k first.", vim.log.levels.WARN)
    return
  end

  local locations = parse_mlir_locations(mlir_file)

  if #locations == 0 then
    vim.notify("No loc() attributes found in MLIR. Firefly may need to emit locations.", vim.log.levels.WARN)
    vim.cmd('vsplit ' .. mlir_file)
    return
  end

  -- Find closest match for current source position
  local best_match = nil
  local best_dist = math.huge

  for _, loc in ipairs(locations) do
    -- Match by filename (handle both full path and basename)
    if loc.src_file:match(src_file .. '$') or src_file:match(loc.src_file .. '$') then
      local dist = math.abs(loc.src_line - src_line)
      if dist < best_dist then
        best_dist = dist
        best_match = loc
      end
    end
  end

  -- Open MLIR file in vertical split
  vim.cmd('vsplit ' .. mlir_file)

  if best_match then
    vim.fn.cursor(best_match.mlir_line, 1)
    vim.cmd('normal! zz')
    vim.notify(string.format("Jumped to MLIR line %d (from %s:%d)",
      best_match.mlir_line, best_match.src_file, best_match.src_line), vim.log.levels.INFO)
  else
    vim.notify("No matching loc() found for " .. src_file .. ":" .. src_line, vim.log.levels.INFO)
  end
end

--- Jump from MLIR loc() attribute back to F# source
function M.jump_to_source()
  local line = vim.fn.getline('.')
  local file, src_line, src_col = line:match('loc%("([^"]+)":(%d+):(%d+)%)')

  if not file then
    -- Try to find loc() on nearby lines
    local current_line = vim.fn.line('.')
    for offset = 1, 5 do
      for _, l in ipairs({current_line - offset, current_line + offset}) do
        if l > 0 then
          local nearby = vim.fn.getline(l)
          file, src_line, src_col = nearby:match('loc%("([^"]+)":(%d+):(%d+)%)')
          if file then break end
        end
      end
      if file then break end
    end
  end

  if file then
    -- Try to find the file
    local full_path = file
    if vim.fn.filereadable(full_path) == 0 then
      -- Search in common locations
      local cwd = vim.fn.getcwd()
      local candidates = {
        cwd .. '/' .. file,
        cwd .. '/src/' .. file,
        vim.fn.expand('%:p:h:h') .. '/' .. file,  -- Parent of MLIR file's parent
      }
      for _, candidate in ipairs(candidates) do
        if vim.fn.filereadable(candidate) == 1 then
          full_path = candidate
          break
        end
      end
    end

    -- Go to previous window and open source
    vim.cmd('wincmd p')
    vim.cmd('edit ' .. full_path)
    vim.fn.cursor(tonumber(src_line), tonumber(src_col))
    vim.cmd('normal! zz')
  else
    vim.notify("No loc() attribute found on or near this line", vim.log.levels.WARN)
  end
end

--- Get info about MLIR file for current project
function M.info()
  local mlir_file = find_mlir_for_project()
  if mlir_file then
    local locations = parse_mlir_locations(mlir_file)
    vim.notify(string.format("MLIR: %s (%d loc() attributes)", mlir_file, #locations), vim.log.levels.INFO)
  else
    vim.notify("No MLIR file found for current project", vim.log.levels.INFO)
  end
end

return M
