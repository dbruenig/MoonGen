local ffi = require "ffi"

require "utils"
require "headers"

local eth = require "proto.ethernet"
local ip = require "proto.ip"
local ip6 = require "proto.ip6"

local ntoh, hton = ntoh, hton
local ntoh16, hton16 = ntoh16, hton16
local bor, band, bnot, rshift, lshift= bit.bor, bit.band, bit.bnot, bit.rshift, bit.lshift
local istype = ffi.istype
local format = string.format


------------------------------------------------------------------------------
--- TCP header
------------------------------------------------------------------------------

local tcpHeader = {}
tcpHeader.__index = tcpHeader

function tcpHeader:setSrcPort(int)
	int = int or 1025
	self.src = hton16(int)
end

function tcpHeader:getSrcPort()
	return hton16(self.src)
end

function tcpHeader:getSrcPortString()
	return self:getSrcPort()
end

function tcpHeader:setDstPort(int)
	int = int or 1024
	self.dst = hton16(int)
end

function tcpHeader:getDstPort()
	return hton16(self.dst)
end

function tcpHeader:getDstPortString()
	return self:getDstPort()
end

function tcpHeader:setSeqNumber(int)
	int = int or 0
	self.seq = hton(int)
end

function tcpHeader:getSeqNumber()
	return hton(self.seq)
end

function tcpHeader:getSeqNumberString()
	return self:getSeqNumber()
end

function tcpHeader:setAckNumber(int)
	int = int or 0
	self.ack = hton(int)
end

function tcpHeader:getAckNumber()
	return hton(self.ack)
end

function tcpHeader:getAckNumberString()
	return self:getAckNumber()
end

-- 4 bit, header size in 32 bit words (min. 5 (no options), max. 15)
function tcpHeader:setDataOffset(int)
	int = int or 5 
	int = band(lshift(int, 4), 0xf0) -- fill to 8 bits
	
	old = self.offset
	old = band(old, 0x0f) -- remove old value
	
	self.offset = bor(old, int)
end

function tcpHeader:getDataOffset()
	return band(rshift(self.offset, 4), 0x0f)
end

function tcpHeader:getDataOffsetString()
	return format("0x%01x", self:getDataOffset())
end

-- 6 bit (4 bit offset, 2 bit flags)
function tcpHeader:setReserved(int)
	int = int or 0
	-- offset  |   flags
	-- XXXXOOOO OOXXXXXX
	--     reserved

	-- first, offset field
	off = band(rshift(int, 2), 0x0f) -- fill to 8 bits (4 highest to 4 lowest bits)
	
	old = self.offset
	old = band(old, 0xf0) -- remove old value
	
	self.offset = bor(old, off)

	-- secondly, flags field
	fla = lshift(int, 6) -- fill to 8 bits (2 lowest to 2 highest bits)
	
	old = self.flags
	old = band(old, 0x3f) -- remove old values

	self.flags = bor(old, fla)
end

function tcpHeader:getReserved()
	res = lshift(band(self.offset, 0x0f), 2) 	-- 4 lowest from offset to 4 highest from reserved
	res = bor(res, rshift(self.flags, 6)) 		-- 2 highest from flags to 2 lowest from reserved
	return res
end

function tcpHeader:getReservedString()
	return format("0x%02x", self:getReserved())
end

-- TODO RFC 3168 specifies new CWR and ECE flags (reserved reduced to 4 bit)
-- 6bit
function tcpHeader:setFlags(int)
	int = int or 0

	int = band(int, 0x3f) -- fill to 8 bits
	
	old = self.flags
	old = band(old, 0xc0) -- remove old values

	self.flags = bor(old, int)
end

function tcpHeader:getFlags()
	return band(self.flags, 0x3f)
end

function tcpHeader:getFlagsString()
	return format("0x%02x", self:getFlags())
end

function tcpHeader:setUrg()
	self.flags = bor(self.flags, 0x20)
end

function tcpHeader:unsetUrg()
	self.flags = band(self.flags, 0xdf)
end

function tcpHeader:getUrg()
	return rshift(band(self.flags, 0x20), 5)
end

function tcpHeader:getUrgString()
	if self:getUrg() == 1 then
		return "URG"
	else
		return "X"
	end
end

function tcpHeader:setAck()
	self.flags = bor(self.flags, 0x10)
end

function tcpHeader:unsetAck()
	self.flags = band(self.flags, 0xef)
end

function tcpHeader:getAck()
	return rshift(band(self.flags, 0x10), 4)
end

function tcpHeader:getAckString()
	if self:getAck() == 1 then
		return "ACK"
	else
		return "X"
	end
end

function tcpHeader:setPsh()
	self.flags = bor(self.flags, 0x08)
end

function tcpHeader:unsetPsh()
	self.flags = band(self.flags, 0xf7)
end

function tcpHeader:getPsh()
	return rshift(band(self.flags, 0x08), 3)
end

function tcpHeader:getPshString()
	if self:getPsh() == 1 then
		return "PSH"
	else
		return "X"
	end
end

function tcpHeader:setRst()
	self.flags = bor(self.flags, 0x04)
end

function tcpHeader:unsetRst()
	self.flags = band(self.flags, 0xfb)
end

function tcpHeader:getRst()
	return rshift(band(self.flags, 0x04), 2)
end

function tcpHeader:getRstString()
	if self:getRst() == 1 then
		return "RST"
	else
		return "X"
	end
end

function tcpHeader:setSyn()
	self.flags = bor(self.flags, 0x02)
end

function tcpHeader:unsetSyn()
	self.flags = band(self.flags, 0xfd)
end

function tcpHeader:getSyn()
	return rshift(band(self.flags, 0x02), 1)
end

function tcpHeader:getSynString()
	if self:getSyn() == 1 then
		return "SYN"
	else
		return "X"
	end
end

function tcpHeader:setFin()
	self.flags = bor(self.flags, 0x01)
end

function tcpHeader:unsetFin()
	self.flags = band(self.flags, 0xfe)
end

function tcpHeader:getFin()
	return band(self.flags, 0x01)
end

function tcpHeader:getFinString()
	if self:getFin() == 1 then
		return "FIN"
	else
		return "X"
	end
end

function tcpHeader:setWindow(int)
	int = int or 0
	self.window = hton16(int)
end

function tcpHeader:getWindow()
	return hton16(self.window)
end

function tcpHeader:getWindowString()
	return self:getWindow()
end

function tcpHeader:setChecksum(int)
	int = int or 0
	self.cs = hton16(int)
end

function tcpHeader:getChecksum()
	return hton16(self.cs)
end

function tcpHeader:getChecksumString()
	return format("0x%04x", self:getChecksum())
end

function tcpHeader:setUrgentPointer(int)
	int = int or 0
	self.urg = hton16(int)
end

function tcpHeader:getUrgentPointer()
	return hton16(self.urg)
end

function tcpHeader:getUrgentPointerString()
	return self:getUrgentPointer()
end

-- TODO how do we want to handle options (problem is tcp header variable length array of uint8[] followed by payload variable length array (uint8[]))
--[[function tcpHeader:setOptions(int)
	int = int or
	self. = int
end--]]

function tcpHeader:fill(args)
	args = args or {}
	self:setSrcPort(args.tcpSrc)
	self:setDstPort(args.tcpDst)
	self:setSeqNumber(args.tcpSeqNumber)
	self:setAckNumber(args.tcpAckNumber)
	self:setDataOffset(args.tcpDataOffset)
	self:setReserved(args.tcpReserved)
	self:setFlags(args.tcpFlags)
	if args.tcpUrg and args.tcpUrg ~= 0 then
		self:setUrg()
	end
	if args.tcpAck and args.tcpAck ~= 0 then
		self:setAck()
	end
	if args.tcpPsh and args.tcpPsh ~= 0 then
		self:setPsh()
	end
	if args.tcpRst and args.tcpRst ~= 0 then
		self:setRst()
	end
	if args.tcpSyn and args.tcpSyn ~= 0 then
		self:setSyn()
	end
	if args.tcpFin and args.tcpFin ~= 0 then
		self:setFin()
	end
	self:setWindow(args.tcpWindow)
	self:setChecksum(args.tcpChecksum)
	self:setUrgentPointer(args.tcpUrgentPointer)
end

--- Retrieve the values of all members.
-- @return Table of named arguments. For a list of arguments see "See also".
-- @see tcpHeader:fill
function tcpHeader:get()
	return { tcpSrc			= self:getSrcPort(),
		 tcpDst			= self:getDstPort(),
		 tcpSeqNumber		= self:getSeqNumber(),
		 tcpAckNumber		= self:getAckNumber(),
		 tcpDataOffset		= self:getDataOffset(),
		 tcpReserved		= self:getReserved(),
		 tcpFlags		= self:getFlags(),
		 tcpUrg			= self:getUrg(),
		 tcpAck			= self:getAck(),
		 tcpPsh			= self:getPsh(),
		 tcpRst			= self:getRst(),
		 tcpSyn			= self:getSyn(),
		 tcpFin			= self:getFin(),
		 tcpWindow		= self:getWindow(),
		 tcpChecksum		= self:getChecksum(),
		 tcpUrgentPointer	= self:getUrgentPointer()
		}
end

--- Retrieve the values of all members.
-- @return Values in string format.
function tcpHeader:getString()
	return "TCP " 		.. self:getSrcPortString() 
		.. " > " 	.. self:getDstPortString() 
		.. " seq# " 	.. self:getSeqNumberString()
		.. " ack# " 	.. self:getAckNumberString() 
		.. " offset " 	.. self:getDataOffsetString() 
		.. " reserved " .. self:getReservedString()
		.. " flags " 	.. self:getFlagsString() 
		.. " [" 	.. self:getUrgString() 
		.. "|" 		.. self:getAckString() 
		.. "|" 		.. self:getPshString() 
		.. "|" 		.. self:getRstString() 
		.. "|" 		.. self:getSynString() 
		.. "|" 		.. self:getFinString()
		.."] win " 	.. self:getWindowString() 
		.. " cksum " 	.. self:getChecksumString() 
		.. " urg " 	.. self:getUrgentPointerString() 
end


--------------------------------------------------------------------------------
--- TCPv4 packets
--------------------------------------------------------------------------------

local tcp4Packet = {}
local tcp4PacketType = ffi.typeof("struct tcp_packet*")
tcp4Packet.__index = tcp4Packet

function tcp4Packet:fill(args)
	args = args or {}

	-- calculate length value for ip headers
	if args.pktLength then
		args.ipLength = args.ipLength or args.pktLength - 14 -- ethernet
	end
	
	-- rewrite default values
	args.ipProtocol = args.ipProtocol or ip.PROTO_TCP
	
	self.eth:fill(args)
	self.ip:fill(args)
	self.tcp:fill(args)
end

function tcp4Packet:get()
	return mergeTables(self.eth:get(), self.ip:get(), self.tcp:get())
end

function tcp4Packet:dump(bytes)
	dumpPacket(self, bytes, self.eth, self.ip, self.tcp)
end

function tcp4Packet:calculateTcpChecksum()
	-- TODO
	self.tcp:setChecksum()
end


----------------------------------------------------------------------------------
--- TCPv6 packets
----------------------------------------------------------------------------------

local tcp6Packet = {}
local tcp6PacketType = ffi.typeof("struct tcp_v6_packet*")
tcp6Packet.__index = tcp6Packet

function tcp6Packet:fill(args)
	args = args or {}

	-- calculate length value for ip headers
	if args.pktLength then
		args.ip6Length = args.ip6Length or args.pktLength - (14 + 40) -- ethernet + ip
	end
	
	-- rewrite default values
	args.ethType = args.ethType or eth.TYPE_IP6
	args.ip6NextHeader = args.ip6NextHeader or ip6.PROTO_TCP

	self.eth:fill(args)
	self.ip:fill(args)
	self.tcp:fill(args)
end

function tcp6Packet:get()
	return mergeTables(self.eth:get(), self.ip:get(), self.tcp:get())
end

function tcp6Packet:dump(bytes)
	dumpPacket(self, bytes, self.eth, self.ip, self.tcp)
end

function tcp6Packet:calculateTcpChecksum()
	-- TODO
	self.tcp:setChecksum()
end


------------------------------------------------------------------------------------
--- Metatypes
------------------------------------------------------------------------------------

ffi.metatype("struct tcp_header", tcpHeader)
ffi.metatype("struct tcp_packet", tcp4Packet)
ffi.metatype("struct tcp_v6_packet", tcp6Packet)
