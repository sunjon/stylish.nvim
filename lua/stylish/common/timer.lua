local Clock = {}

function Clock.get_time()
  local uv = vim.loop
  return uv.now() / 1000
end

-- TODO: this should be a method of animation_timer
function Clock.update_delta_time(animation_timer)
  local get_time = Clock.get_time

  local time_now = get_time()
  local delta_time = time_now - animation_timer.last_frame
  --
  animation_timer.last_frame = time_now
  animation_timer.elapsed = animation_timer.elapsed + delta_time

  return animation_timer
end

return Clock
