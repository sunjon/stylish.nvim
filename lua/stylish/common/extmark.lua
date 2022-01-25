local api = vim.api

local char_map = {
  [0] = " ",
  [1] = "",
  [2] = "█",
  [3] = "",
}

local M = {}

-- creates a batch of extmarks with no attributes
function M.create_batch(bufnr, nsid, n)
  local extmark_ids = {}
  for i = 1, n do
    extmark_ids[i] = api.nvim_buf_set_extmark(bufnr, nsid, i, 0, {virt_text_pos="overlay"})
  end

  return extmark_ids
end

-- TODO: make this more generic or move it to clock.lua
function M.row_to_chunks(row_values, row_len, hl_callback)
  local chunks = {}
  local chunk_virt_text, chunk_hl_group, cell_value, last_cell_value

  chunk_virt_text = ""
  for i = 1, #row_values + 1 do
    cell_value = row_values[i]

    if cell_value == last_cell_value then
      chunk_virt_text = chunk_virt_text .. char_map[cell_value]
    else
      if chunk_virt_text ~= "" then
        chunk_hl_group = hl_callback(last_cell_value)
        chunks[#chunks + 1] = { chunk_virt_text, chunk_hl_group }
      end

      last_cell_value = cell_value
      chunk_virt_text = char_map[cell_value]
    end
  end

  -- pad to row_len with zeros
  for _=#row_values, row_len do
    chunks[#chunks + 1] = {" ", hl_callback(0)}
  end

  return chunks

end

return M
