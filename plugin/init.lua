--- Packer will compile lua files, as a result `<sfile>` will appear to be the compiled cache file.
-- <my_plugin>/plugin/init.lua file seems to work though

vim.api.nvim_set_var('stylish_data_dir', vim.fn.expand('<sfile>:p:h:h') .."/data/")
