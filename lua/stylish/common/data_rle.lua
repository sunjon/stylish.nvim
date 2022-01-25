local ascii_decode_LUT = {
  [0x20] = " ",
  [0x2580] = "▀",
  [0x2581] = "▁",
  [0x2584] = "▄",
  [0x2588] = "█",
  [0x2590] = "▐",
  [0x2595] = "▕",
  [0x2598] = "▘",
  [0x259B] = "▛",
  [0xE0BA] = "",
  [0xE0B8] = "",
  [0xE0BC] = "",
  [0xE0BE] = "",
}

local function rle_decode(row_char_chunks)
  local chunk_length, chunk_value
  local result = {}
  for _, chunk in ipairs(row_char_chunks) do
    chunk_length = chunk[1]
    chunk_value = chunk[2]
    for _ = 1, chunk_length do
      result[#result + 1] = chunk_value
    end
  end

  return result
end

local M = {}

function M.import_datafile(filepath)
  local fileread = io.open(filepath, "r")
  if not fileread then
    return
  end

  local file_content = fileread:read()
  fileread:close()

  local f = loadstring(file_content)
  return f()
end

function M.decode_datafile(encoded_source)
  local result = {}
  for i, row_data in ipairs(encoded_source) do
    local row_characters = row_data.c
    local row_colors_fg = rle_decode(row_data.fg)
    local row_colors_bg = rle_decode(row_data.bg)

    -- print(vim.inspect(row_data))
    local row_cells = {}
    for _, val in ipairs(rle_decode(row_characters)) do
      local column = #row_cells + 1
      local cell = {
        char = ascii_decode_LUT[tonumber(val)],
        fg = row_colors_fg[column],
        bg = row_colors_bg[column],
        -- brightness = 32, -- default brightness - TODO: Make this dynamic or based on user config
        brightness = 1, -- default brightness - TODO: Make this dynamic or based on user config
      }
      row_cells[column] = cell
    end
    result[i] = row_cells
  end

  return result
end

return M
