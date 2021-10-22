local EventEmitter = require("core.EventEmitter")
local Logger       = require("core.Logger")
local tconcat      = table.concat
local schar        = string.char
local stringx      = require("pl.stringx")
local wrapper      = require("core.lib.wrapper")
local socket       = require("skynet.socket")
local class        = require("pl.class")

local Telnet       = {}
local Seq          = {
  IAC  = schar(255),
  DONT = schar(254),
  DO   = schar(253),
  WONT = schar(252),
  WILL = schar(251),
  SB   = schar(250),
  SE   = schar(240),
  GA   = schar(249),
  EOR  = schar(239),
  GMCP = schar(201),
};
Telnet.Sequences = Seq;

local Opts         = {
  OPT_ECHO = schar(1),
  OPT_EOR  = schar(25),
  OPT_GMCP = schar(201),
}
Telnet.Options = Opts;

---A TelnetSocket is a Socket which handle telnet options and data's
---It will attach to a Socket, and will attached by a TelnetStream
---It will set the Socket's event callback.
---@class TelnetSocket : EventEmitter
---@field socket Socket #skynet socket wrapper
---@field maxInputLength number #max characters per input
---@field echoing boolean # is echoing
---@field gaMode string @ telnet gamode
local TelnetSocket = class(EventEmitter)

function TelnetSocket:_init(opts)
  opts = opts or {}
  self:super()
  self.socket = nil
  self.maxInputLength = opts.maxInputLength or 512
  self.echoing = true
  self.gaMode = nil
end

function TelnetSocket:readable() return self.socket:readable(); end

function TelnetSocket:writable() return self.socket:writable(); end

function TelnetSocket:address() return self.socket and self.socket:address(); end

function TelnetSocket:stop() self.socket:stop(); end

--- Here will handle telnet IAC.
---@param data string binary
---@param encoding? string utf8
function TelnetSocket:write(data, encoding)
  data = data:gsub(".", function(c)
    if c == Seq.IAC then
      return c .. c
    else
      return c
    end
  end)
  self.socket:write(data)
end

function TelnetSocket:pause() self.socket:pause(); end

function TelnetSocket:resume() self.socket:resume(); end

function TelnetSocket:destroy() self.socket:destroy(); end

---
---Execute a telnet command
---@param willingness number DO/DONT/WILL/WONT
---@param command number|number[] command     Option to do/don't do or subsequence as array
function TelnetSocket:telnetCommand(willingness, command)
  local seq = { Seq.IAC, willingness }
  if type(command) == "table" then
    for i, cmd in ipairs(command) do seq[#seq + 1] = cmd end
  else
    seq[#seq + 1] = command
  end
  self.socket:write(tconcat(seq, ""));
end

function TelnetSocket:toggleEcho()
  self.echoing = not self.echoing;
  self:telnetCommand(self.echoing and Seq.WONT or Seq.WILL, Opts.OPT_ECHO);
end

---
---Send a GMCP message
---https://www.gammon.com.au/gmcp
---
---@param gmcpPackage string gmcpPackage
---@param data  any       JSON.stringify-able data or we need cjson? must json
---
function TelnetSocket:sendGMCP(gmcpPackage, data)
  self.socket.write(tconcat({
    Seq.IAC,
    Seq.SB,
    Seq.GMCP,
    gmcpPackage,
    " ",
    data,
    Seq.IAC,
    Seq.SE,
  }));
end

---comment
---@param connection Socket #maybe rawSocket?
function TelnetSocket:attach(connection)
  self.socket = connection;

  --- Proxy the socket  error
  connection:on("error", function(err) return self:emit("error", err) end);
  --- Handle telnet command and emit the data
  connection:on("data", function(databuf)
    Logger.debug("TelnetSocket.onData:%q", databuf)
    -- immediately start consuming data if we begin receiving normal data
    -- instead of telnet negotiation
    if connection.fresh and databuf:sub(1, 1) ~= Seq.IAC then
      connection.fresh = false;
    end
    -- fresh makes sure that even if we haven't gotten a newline but the client
    -- sent us some initial negotiations to still interpret them
    if not databuf:find("\r\n") and not connection.fresh then return; end

    -- If multiple commands were sent \r\n separated in the same packet process
    -- them separately. Some client auto-connect features do self
    for _, data in ipairs(stringx.split(databuf, "\r\n")) do
      if #data > 0 then self:input(data) end
    end
  end);
  ---Proxy socket close event
  connection:on("close", function() self:emit("close") end);
end

---
---Parse telnet input socket, swallowing any negotiations
---and emitting clean, fresh data
---
---@param inputbuf string binary inputbuf
---
---@fires TelnetSocket#DO
---@fires TelnetSocket#DONT
---@fires TelnetSocket#GMCP
---@fires TelnetSocket#SUBNEG
---@fires TelnetSocket#WILL
---@fires TelnetSocket#WONT
---@fires TelnetSocket#data
---@fires TelnetSocket#unknownAction
---
function TelnetSocket:input(inputbuf)
  Logger.debug("Input:%q", inputbuf)
  if not inputbuf:find(Seq.IAC) then return self:emit("data", inputbuf) end
  -- strip any negotiations
  local cleanbuf     = {}
  local i            = 1;
  local cleanlen     = 1;
  local subnegBuffer
  local subnegOpt   

  while i <= #inputbuf do
    if inputbuf:sub(i, 1) ~= Seq.IAC then
      cleanbuf[cleanlen] = inputbuf[i]
      cleanlen = cleanlen + 1
      i = i + 1
      goto continue
    end

    local cmd = inputbuf:sub(i + 1, 1)
    local opt = inputbuf:sub(i + 2, 1)
    if cmd == Seq.DO then
      if opt == Opts.OPT_EOR then
        self.gaMode = Seq.EOR
      else
        self:emit("DO", opt)
      end
      i = i + 3
    elseif cmd == Seq.DONT then
      if opt == Opts.OPT_EOR then
        self.gaMode = Seq.GA
      else
        self:emit("DONT", opt)
      end
      i = i + 3
    elseif cmd == Seq.WILL then
      self:emit("WILL", opt)
      i = i + 3
    elseif cmd == Seq.WONT then
      self:emit("WONT", opt)
      i = i + 3
    elseif cmd == Seq.SB then
      i = i + 2
      subnegOpt = inputbuf:sub(i, 1)
      i = i + 1
      subnegBuffer = string.rep(" ", #inputbuf - i)
      local sublen = 1
      while inputbuf:sub(i, 1) ~= Seq.IAC do
        subnegBuffer[#sublen] = inputbuf[i]
        i = i + 1
      end
    elseif cmd == Seq.SE then
      if subnegOpt == Opts.OPT_GMCP then
        local gmcp        = stringx.split(wrapper.trim(subnegBuffer), " ")
        local gmcpPackage = gmcp[1]
        -- to be json
        local gmcpData    = tconcat(gmcp, " ", 2)
        self:emit("GMCP", gmcpPackage, gmcpData)
      else
        self:emit("SUBNET", subnegOpt, subnegBuffer)
      end
      i = i + 2
    else
      self:emit("unknownAction", cmd, opt)
      i = i + 2
    end
    ::continue::
  end

  local data         = tconcat(cleanbuf)
  Logger.debug("INPUT,RESULT:%q", data)
  if #data < 1 then return end
  if self.socket.fresh then
    self.socket.fresh = false;
    return;
  end

  self:emit("data", tconcat(cleanbuf))
end
Telnet.TelnetSocket = TelnetSocket;

---A Socket which use skynet.socket lib to enable socket feature
---And will read from skynet socket id in loop, then emit data.
---@class Socket : EventEmitter
---@field id number @skynet socket index
---@field fresh boolean @is new connect?
---@field addr string @client address
local Socket       = class(EventEmitter)

function Socket:_init(id, addr)
  self:super()
  self.id = id
  self.fresh = true
  self.addr = addr
  socket.start(self.id)
end
function Socket:write(msg) socket.write(self.id, msg) end

function Socket:resume()
  while true do
    local ret, err = socket.read(self.id)
    if not ret then
      Logger.error("socket %q closed", self.id)
      socket.close(self.id)
      return
    end
    Logger.debug("Socket Data,%q", ret)
    self:emit("data", ret)
  end
end
function Socket:pause() socket.pause(self.id) end

function Socket:address() return self.addr end

function Socket:stop() socket.shutdown(self.id) end

function Socket:destroy() socket.close(self.id) end

function Socket:readable()
  return not socket.disconnected(self.id) and not socket.invalid(self.id)
end
function Socket:writable()
  return not socket.disconnected(self.id) and not socket.invalid(self.id)
end

---@class Server : EventEmitter
local Server       = class(EventEmitter)

function Server:_init(accept)
  self:super()
  self.accept = accept
end

function Server:listen(host, port)
  local id = socket.listen(host, port)
  socket.start(id, self.accept)
  return self
end

---@class TelnetServer : EventEmitter
---@field netServer Server
local TelnetServer = class(EventEmitter)

function TelnetServer:_init(listener)
  self.netServer = Server(function(fd, addr)
    local sock = Socket(fd, addr)
    listener(sock)
  end)
  self.netServer:on("error", function(error) self:emit("error", error) end)
  self.netServer:on("uncaughtException",
                    function(error) self:emit("uncaughtException", error) end)

end

Telnet.TelnetServer = TelnetServer

return Telnet
