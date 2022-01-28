-- TODO: use a ContextManager for each type?? (menu/select/notification)
local ContextManager = {}

local registry_size = 0
local internal_register = {}

function ContextManager.add(obj)
  internal_register[obj.canvas.winid] = obj
  registry_size = registry_size + 1
end

function ContextManager.remove(winid)
  if internal_register[winid] then
    internal_register[winid] = nil
    registry_size = registry_size - 1
  end
end

function ContextManager.get(winid)
  return internal_register[winid]
end

function ContextManager.size()
  return registry_size
end

return ContextManager
