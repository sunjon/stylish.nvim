local costate = {
  RUNNING = 'running',
  SUSPENDED = 'suspended',
  DEAD = 'dead',
}

-- local scene = require('scenes/nyan').scene


local time_now
local DEFAULT_UPDATE_INTERVAL = 1000/60

local Animator = {}
Animator.__index = Animator

-- Scene = coroutine
function Animator:new(scene, context, update_interval)
  local this = {}
  setmetatable(this, self)
  self.__index = self

  -- TODO: check scene is a valid coroutine
  this.scene = scene
  this.context = context
  this.update_interval = update_interval or DEFAULT_UPDATE_INTERVAL
  this.timer = vim.loop.new_timer()
  this.frame_count = 0

  return this
end

function Animator:start()
  local context = self.context
  self.timer:start(0, self.update_interval, function()
    local scene = self.scene
    if coroutine.status(scene) == costate.SUSPENDED then
      local success, frame_lines = coroutine.resume(scene, context)
      if not success then
        -- TODO: error and teardown/cleanup
        print(frame_lines)
        print '!!!'
      end
      self.frame_count = self.frame_count + 1
    end
    -- time_last_frame = time_now
  end)
end

function Animator:stop()
  if self.timer then
    self.timer:stop()
    self.timer = nil
  end
end

return Animator


    -- print(self.renderer.frame_count)
    -- if not frame_lines then
    --   frame_lines = cached
    -- else
    --   cached = frame_lines
    -- end

    -- local frame_lines = {}
    -- print(self.renderer.frame_count)

    -- print(vim.inspect(frame_lines))
    -- return frame
    -- print(self.renderer.frame_count)
    -- render_time = get_time() - time_now
    -- print(render_time)
    -- else
    --   current_scene:stop()
    --   current_scene:close()
    --   current_scene= nil
    -- else
    -- print(coroutine.status(current_scene))
