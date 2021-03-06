local ffi = require 'ffi'
local torch = require 'torch'
local ros = require 'ros.env'
local utils = require 'ros.utils'
local tf = ros.tf

local Publisher = torch.class('ros.Publisher', ros)
local Publisher_ptr_ct = ffi.typeof('ros_Publisher *')

function init()
  local Publisher_method_names = {
    'clone',
    'delete',
    'shutdown',
    'getTopic',
    'getNumSubscribers',
    'isLatched',
    'publish'
  }

  return utils.create_method_table('ros_Publisher_', Publisher_method_names)
end

local f = init()

function Publisher:__init(ptr, msg_spec, connect_cb, disconnect_cb)
  if not ptr or not ffi.typeof(ptr) == Publisher_ptr_ct then
    error('argument 1: ros::Publisher * expected.')
  end
  self.o = ptr
  self.msg_spec = msg_spec
  self.connect_cb = connect_cb
  self.disconnect_cb = disconnect_cb

  ffi.gc(ptr,
    function(p)
      f.delete(p)
      if self.connect_cb ~= nil then
        self.connect_cb:free()      -- free connect callback
        self.connect_cb = nil
      end
      if self.disconnect_cb ~= nil then
        self.disconnect_cb:free()   -- free disconnet callback
        self.disconnect_cb = nil
      end
    end
  )

end

function Publisher:cdata()
  return self.o
end

function Publisher:clone()
  local c = torch.factory('ros.Publisher')()
  rawset(c, 'o', f.clone(self.o))
  rawset(c, 'msg_spec', self.msg_spec)
  return c
end

function Publisher:shutdown()
  f.shutdown(self.o)
end

function Publisher:getTopic()
  return ffi.string(f.getTopic(self.o))
end

function Publisher:getNumSubscribers()
  return f.getNumSubscribers(self.o)
end

function Publisher:isLatched()
  return f.isLatched(self.o)
end

function Publisher:publish(msg)
  -- serialize message to byte storage
  local v = msg:serialize()
  v:shrinkToFit()
  f.publish(self.o, v.storage:cdata(), 0, v.length)
end

function Publisher:waitForSubscriber(min_count, timeout)
  if not ros.Time.isValid() then
    ros.Time.init()
  end

  min_count = min_count or 1
  if timeout and not torch.isTypeOf(timeout, ros.Duration) then
    timeout = ros.Duration(timeout)
  end

  local start = ros.Time.getNow()
  while true do
    if timeout and (ros.Time.getNow() - start) > timeout then
      return false
    elseif self:getNumSubscribers() >= min_count then
      return true
    end
    ros.spinOnce()
    sys.sleep(0.001)
  end
end

function Publisher:createMessage()
  return ros.Message(self.msg_spec)
end
