--- a global id generator. Every service can use this library
--- Use skynet's tick number as timestamp, which unit is 1/100 S.
--- this value from settings
local serverBeginTime = os.time()

local serverId        = 1
local machineId       = 1
local skynetId        = 1
local crc             = 3

--- we setting here
local lenServerId     = 8
local lenMachineId    = 2
local lenSkynetId     = 3
local lenCrc          = 2
local lenLogicId      = 5
local lenTime         = 32
local lenSeq          = 12

--- cacl shifts
local shiftServerId   = 64 - lenServerId
local shiftMachineId  = shiftServerId - lenMachineId
local shiftSkynetId   = shiftMachineId - lenSkynetId
local shiftCrc        = shiftSkynetId - lenCrc
local shiftLogicId    = shiftCrc - lenLogicId
local shiftTime       = shiftLogicId - lenTime

local prefix          =
  serverId << shiftServerId | machineId << shiftMachineId | skynetId <<
    shiftSkynetId | crc << shiftCrc

--- ensure our set is not greater than 64
local function ensureLength()
  local len = lenServerId + lenMachineId + lenSkynetId + lenCrc + lenLogicId +
                lenSeq + lenTime
  assert(len <= 64, "id length is error")
end

ensureLength()

local lastTime        = os.time()
local seq             = 0
local function idgen(logic)
  logic = logic or 0
  assert(logic <= 2 ^ lenLogicId,
         string.format("logic id is greater than %d", 2 ^ lenLogicId))
  local now = os.time()
  if now > lastTime then
    lastTime = now
    seq = 0
  end
  if seq > 2 ^ lenSeq then
    seq = 0
    lastTime = lastTime + 1
  end
  seq = seq + 1
  return prefix | logic << shiftLogicId | (lastTime - serverBeginTime) <<
           shiftTime | seq
end

return idgen
