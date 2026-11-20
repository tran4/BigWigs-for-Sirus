--------------------------------------------------------------------------------
-- 3.3.5 replacement for C_EncodingUtil (retail only), used by the sharing code
-- for import/export strings.
--
-- Serialization uses LibSerialize instead of CBOR and compression uses LibDeflate
-- (v1.0.2+, zlib license, the same copy WeakAuras on Sirus ships), so the strings
-- are not compatible with retail BigWigs, which is fine, the content isn't either.
-- Strings from retail BigWigs fail to decode gracefully (nil is returned).
--

local _, addonTable = ...
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

local EncodingUtil = {}
addonTable.EncodingUtil = EncodingUtil

function EncodingUtil.SerializeCBOR(value)
	return LibSerialize:Serialize(value)
end

function EncodingUtil.DeserializeCBOR(str)
	if type(str) ~= "string" then return end
	local ok, success, value = pcall(LibSerialize.Deserialize, LibSerialize, str)
	if ok and success then
		return value
	end
end

function EncodingUtil.CompressString(str)
	return LibDeflate:CompressDeflate(str, {level = 9})
end

function EncodingUtil.DecompressString(str)
	if type(str) ~= "string" then return end
	local ok, result = pcall(LibDeflate.DecompressDeflate, LibDeflate, str)
	if ok and result then
		return result
	end
	return str -- Uncompressed strings from early test builds
end

do
	local byte, char, sub, floor, concat = string.byte, string.char, string.sub, math.floor, table.concat
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local encodeTable, decodeTable = {}, {}
	for i = 1, 64 do
		local c = sub(alphabet, i, i)
		encodeTable[i - 1] = c
		decodeTable[byte(c)] = i - 1
	end

	function EncodingUtil.EncodeBase64(str)
		local out, n = {}, 0
		local len = #str
		for i = 1, len, 3 do
			local a, b, c = byte(str, i, i + 2)
			local value = a * 65536 + (b or 0) * 256 + (c or 0)
			local c1 = floor(value / 262144)
			local c2 = floor(value / 4096) % 64
			local c3 = floor(value / 64) % 64
			local c4 = value % 64
			n = n + 1
			if c then
				out[n] = encodeTable[c1] .. encodeTable[c2] .. encodeTable[c3] .. encodeTable[c4]
			elseif b then
				out[n] = encodeTable[c1] .. encodeTable[c2] .. encodeTable[c3] .. "="
			else
				out[n] = encodeTable[c1] .. encodeTable[c2] .. "=="
			end
		end
		return concat(out)
	end

	function EncodingUtil.DecodeBase64(str)
		if type(str) ~= "string" then return end
		str = str:gsub("%s", "") -- Ignore line breaks/spaces from copy & paste
		local len = #str
		if len == 0 then return "" end
		if len % 4 ~= 0 then return end
		local out, n = {}, 0
		for i = 1, len, 4 do
			local b1, b2, b3, b4 = byte(str, i, i + 3)
			local v1, v2 = decodeTable[b1], decodeTable[b2]
			if not v1 or not v2 then return end
			local pad3, pad4 = b3 == 61, b4 == 61 -- "="
			local v3 = pad3 and 0 or decodeTable[b3]
			local v4 = pad4 and 0 or decodeTable[b4]
			if not v3 or not v4 or (pad3 and not pad4) or ((pad3 or pad4) and i + 3 ~= len) then return end
			local value = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
			local c1 = floor(value / 65536)
			local c2 = floor(value / 256) % 256
			local c3 = value % 256
			n = n + 1
			if pad3 then
				out[n] = char(c1)
			elseif pad4 then
				out[n] = char(c1, c2)
			else
				out[n] = char(c1, c2, c3)
			end
		end
		return concat(out)
	end
end
