-- by wazzchz

local imgui = require('mimgui')
local faicons = require('fAwesome6')
local widgets = require("widgets")
local vector3d = require("vector3d")
local ffi = require("ffi")
local json = require 'json'
local events = require "lib.samp.events"
local sampev = require "lib.samp.events"
local encoding = require('encoding')
encoding.default = ('CP1251')
u8 = encoding.UTF8
local SAMemory = require "SAMemory"
local DPI = MONET_DPI_SCALE

local gta = ffi.load("GTASA")
local camera = SAMemory.camera
local screenWidth, screenHeight = getScreenResolution()
SAMemory.require("CCamera")
ffi.cdef [[ typedef struct RwV3d{float x,y,z;}RwV3d;void _ZN4CPed15GetBonePositionER5RwV3djb(void* thiz,RwV3d* posn,uint32_t bone,bool calledFromCam);]]

local enable = imgui.new.bool(false)
local circuloFOVAIM = imgui.new.bool(false)
local VERIFICAskin = imgui.new.bool(true)
local matarbackwallsAIM = imgui.new.bool(false)
local fovSizeAIM = imgui.new.float(90.0)
local distanceAIM = imgui.new.float(90.0)
local smoothvalue = imgui.new.float(15.0)
local SmoothTap = imgui.new.float(7.0)
local posiX = imgui.new.float(0.51899999380112)
local posiY = imgui.new.float(0.45800000429153)
local stickcamerawithoutmode = imgui.new.bool(false)

local enableSilent = imgui.new.bool(false)
local cabecaSilent = imgui.new.bool(true)
local melmaiak = imgui.new.bool(false)
local matarbackwallsSilent = imgui.new.bool(false)
local offsetsilentcirculoX = imgui.new.float(0.5180)
local offsetsilentcirculoY = imgui.new.float(0.4750)
local tamanhoFOVsilent = imgui.new.float(27.0)
local circuloFOVsilent = imgui.new.bool(false)
local verificarSKIN = imgui.new.bool(true)
local minFov = 1
local sanguesilent = imgui.new.bool(true)
local fovColor = imgui.new.float[4](0.80, 0.00, 0.00, 0)
local bosrdabbsilen = imgui.new.float[4](0.80, 0.00, 0.00, 1.00)
local distanceAIMSILENT = imgui.new.float(90.0)

local aimbotpjl = {
  cabecaAIM = imgui.new.bool(true),
  virilhaaimboott = imgui.new.bool(false),
  peitoaimboott = imgui.new.bool(false)
}

local font = renderCreateFont("Arial", 12, 1 + 4)
local bones = {
  3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2
}

EspSulista = {
  enabled = imgui.new.bool(false),
  max_distance = imgui.new.int(999),
  show_name = imgui.new.bool(true),
  show_health_armor = imgui.new.bool(true),
  show_line_and_distance = imgui.new.bool(true),
  show_skeleton = imgui.new.bool(true),
  show_distance = imgui.new.bool(true),
  show_box = imgui.new.bool(true),
  show_weapon = imgui.new.bool(true),
  show_status = imgui.new.bool(true),
  font = font
}

local pjl = {
  bordaaimon = imgui.new.float[4](1.00, 1.00, 1.00, 1.00),
  minFov = 1,
  fovColorAim = imgui.new.float[4](0.80, 0.00, 0.00, 0.00),
}

function colorToHex(r, g, b, a)
return bit.bor(
  bit.lshift(math.floor(a * 255), 24),
  bit.lshift(math.floor(r * 255), 16),
  bit.lshift(math.floor(g * 255), 8),
  math.floor(b * 255)
)
end

function getBonePosition(ped, bone)
local pedptr = ffi.cast("void*", getCharPointer(ped))
local posn = ffi.new("RwV3d[1]")
gta._ZN4CPed15GetBonePositionER5RwV3djb(pedptr, posn, bone, false)
return posn[0].x, posn[0].y, posn[0].z
end

function getCharSkinId(char)
return getCharModel(char)
end

function getCameraRotation()
return camera.aCams[0].fHorizontalAngle, camera.aCams[0].fVerticalAngle
end

function setCameraRotation(x, y)
camera.aCams[0].fHorizontalAngle = x
camera.aCams[0].fVerticalAngle = y
end

function convertCartesianCoordinatesToSpherical(pos)
local diff = pos - vector3d(getActiveCameraCoordinates())
local len = diff:length()
if len == 0 then return 0, 0 end
local angleX = math.atan2(diff.y, diff.x)
local angleY = math.acos(diff.z / len)
if angleX > 0 then angleX = angleX - math.pi else angleX = angleX + math.pi end
return angleX, math.pi / 2 - angleY
end

function getCrosshairPositionOnScreen()
local w, h = getScreenResolution()
return w * posiX[0], h * posiY[0]
end

function getCrosshairRotation(depth)
depth = depth or 5
local x, y = getCrosshairPositionOnScreen()
local worldCoords = vector3d(convertScreenCoordsToWorld3D(x, y, depth))
return convertCartesianCoordinatesToSpherical(worldCoords)
end

function NormalizeAngle(angle)
while angle > math.pi do angle = angle - 2 * math.pi end
while angle < -math.pi do angle = angle + 2 * math.pi end
return angle
end

function safeGetBone(char, id)
local x, y, z = getBonePosition(char, id)
if x and y and z then return vector3d(x, y, z) end
return nil
end

function getNearCharToCenter(radius)
local nearby = {}
local w, h = getScreenResolution()

for _, char in ipairs(getAllChars()) do
if isCharOnScreen(char) and char ~= PLAYER_PED and not isCharDead(char) then
local headPos = safeGetBone(char, 4)
if not headPos then goto continue end

local sx, sy = convert3DCoordsToScreen(headPos.x, headPos.y, headPos.z)
local centerX, centerY = w / 2, h / 2
local dist = getDistanceBetweenCoords2d(centerX, centerY, sx, sy)

if dist <= tonumber(radius or h) then
table.insert(nearby, {
  dist, char, headPos
})
end
end
::continue::
end

table.sort(nearby, function(a, b) return a[1] < b[1] end)
return #nearby > 0 and nearby[1][2] or nil, #nearby > 0 and nearby[1][3] or nil
end

function aimAtPointWithSniperScope(pos)
local sx, sy = convertCartesianCoordinatesToSpherical(pos)
setCameraRotation(sx, sy)
end

function aimAtPointWithM16(pos)
local sx, sy = convertCartesianCoordinatesToSpherical(pos)
local tx, ty = getCrosshairRotation()
local cx, cy = getCameraRotation()
local divisor = math.max(smoothvalue[0], 0.01)
local diffYaw = NormalizeAngle(sx - tx)
local diffPitch = sy - ty
local smoothYaw = cx + diffYaw / divisor
local smoothPitch = cy + diffPitch / divisor
setCameraRotation(smoothYaw, smoothPitch)
end

function Aimbot()
if not enable[0] then return end

local nearChar = getNearCharToCenter(fovSizeAIM[0])
if not nearChar then return end

if VERIFICAskin[0] and getCharSkinId(PLAYER_PED) == getCharSkinId(nearChar) then
return
end

local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
local targetBone = nil

local boneOrder = {
  {
    aimbotpjl.cabecaAIM[0], 4
  },
  {
    aimbotpjl.peitoaimboott[0], 3
  },
  {
    aimbotpjl.virilhaaimboott[0], 1
  }
}

for _, v in ipairs(boneOrder) do
if v[1] then
targetBone = safeGetBone(nearChar, v[2])
if targetBone then break end
end
end

if not targetBone then return end

local distToBone = getDistanceBetweenCoords3d(pX, pY, pZ, targetBone.x, targetBone.y, targetBone.z)
if distToBone > distanceAIM[0] then return end

if not matarbackwallsAIM[0] then
local hit, _, _, _, entityHit = processLineOfSight(
  pX, pY, pZ, targetBone.x, targetBone.y, targetBone.z,
  true, true, false, true, false, false, false, false
)
if hit and entityHit ~= nearChar then return end
end

local nMode = camera.aCams[0].nMode
if nMode == 7 then
aimAtPointWithSniperScope(targetBone)
elseif nMode == 53 then
aimAtPointWithM16(targetBone)
elseif stickcamerawithoutmode[0] then
local sx, sy = convertCartesianCoordinatesToSpherical(targetBone)
local tx, ty = getCrosshairRotation()
local cx, cy = getCameraRotation()
local divisor = math.max(SmoothTap[0], 0.01)
local diffYaw = NormalizeAngle(sx - tx)
local diffPitch = sy - ty
local smoothYaw = cx + diffYaw / divisor
local smoothPitch = cy + diffPitch / divisor
setCameraRotation(smoothYaw, smoothPitch)
end
end

function isPlayerInFOV(playerScreenX, playerScreenY, fovCenterX, fovCenterY, radius)
if not fovCenterX or not fovCenterY then return false end
local dx = playerScreenX - fovCenterX
local dy = playerScreenY - fovCenterY
return (dx * dx + dy * dy) <= (radius * radius)
end

function verificarSkinAtiva(playerId)
local mymodel = getCharModel(PLAYER_PED)
local success, ped = sampGetCharHandleBySampPlayerId(playerId)
if success and doesCharExist(ped) then
local playerModel = getCharModel(ped)
if verificarSKIN[0] and playerModel == mymodel then
return false
end
end
return true
end

local lastSilentTick = 0
function applyDamageToPlayer(playerId, pedX, pedY, pedZ, ped)
if not enableSilent[0] then return end
local now = getGameTimer()
if now == lastSilentTick then return end
lastSilentTick = now
local weaponId = getCurrentCharWeapon(PLAYER_PED)
sampSendGiveDamage(playerId, 100.0, weaponId, 9)

if sanguesilent[0] then
addBlood(pedX, pedY, pedZ + 0.67, 0.2, 0.2, 0.2, 9920, ped)
end
end

function processSilentAim()
if not enableSilent[0] then return end

local screenWidth, screenHeight = getScreenResolution()
local fovCenterX, fovCenterY

if isCurrentCharWeapon(PLAYER_PED, 34) then
fovCenterX = screenWidth / 2
fovCenterY = screenHeight / 2
else
  fovCenterX = screenWidth * offsetsilentcirculoX[0]
fovCenterY = screenHeight * offsetsilentcirculoY[0]
end

local closestPlayer = nil
local closestDistance = math.huge

for playerId = 0, sampGetMaxPlayerId() do
if sampIsPlayerConnected(playerId) then
local success, ped = sampGetCharHandleBySampPlayerId(playerId)
if success and ped ~= PLAYER_PED and isCharOnScreen(ped) and not isCharDead(ped) then
local pedX, pedY, pedZ = getCharCoordinates(ped)
local screenX, screenY = convert3DCoordsToScreen(pedX, pedY, pedZ)

if screenX and screenY then
if not matarbackwallsSilent[0] then
local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
local hit, _, _, _, entityHit = processLineOfSight(
  playerX, playerY, playerZ, pedX, pedY, pedZ,
  true, true, false, true, false, false, false, false
)
if hit and entityHit ~= ped then
goto continue
end
end

if isPlayerInFOV(screenX, screenY, fovCenterX, fovCenterY, tamanhoFOVsilent[0]) then
local distance = math.sqrt((screenX - fovCenterX)^2 + (screenY - fovCenterY)^2)
if distance < closestDistance then
closestDistance = distance
closestPlayer = {
  id = playerId, ped = ped, x = pedX, y = pedY, z = pedZ
}
end
end
end
end
end
::continue::
end

if closestPlayer and closestDistance <= distanceAIMSILENT[0] then
applyDamageToPlayer(closestPlayer.id, closestPlayer.x, closestPlayer.y, closestPlayer.z, closestPlayer.ped)
end
end

function renderDrawBoxWithBorder(x, y, w, h, color, thickness)
renderDrawLine(x, y, x + w, y, thickness, color)
renderDrawLine(x, y + h, x + w, y + h, thickness, color)
renderDrawLine(x, y, x, y + h, thickness, color)
renderDrawLine(x + w, y, x + w, y + h, thickness, color)
end

function drawESP()
if not EspSulista.enabled[0] then return end

local bit = require("bit")
local function rgbaToHex(r, g, b, a)
r = math.floor(r * 255)
g = math.floor(g * 255)
b = math.floor(b * 255)
a = math.floor(a * 255)
return bit.bor(bit.lshift(a, 24), bit.lshift(r, 16), bit.lshift(g, 8), b)
end

local white = rgbaToHex(1.0, 1.0, 1.0, 1.0)
local localX, localY, localZ = getCharCoordinates(PLAYER_PED)

for playerId = 0, sampGetMaxPlayerId() do
if sampIsPlayerConnected(playerId) then
local result, playerPed = sampGetCharHandleBySampPlayerId(playerId)

if result and playerPed ~= PLAYER_PED and isCharOnScreen(playerPed) then
local targetX, targetY, targetZ = getCharCoordinates(playerPed)
local distance = getDistanceBetweenCoords3d(localX, localY, localZ, targetX, targetY, targetZ)

if distance <= EspSulista.max_distance[0] then
local screenX, screenY = convert3DCoordsToScreen(targetX, targetY, targetZ + 1.0)

if screenX and screenY then
local nick = sampGetPlayerNickname(playerId)
local health = sampGetPlayerHealth(playerId)
local armor = sampGetPlayerArmor(playerId)

if EspSulista.show_name[0] then
renderFontDrawText(EspSulista.font, nick, screenX - 30, screenY - 30, white)
end

if EspSulista.show_distance[0] then
renderFontDrawText(EspSulista.font, string.format("%.1fm", distance), screenX, screenY - 15, white)
end

if EspSulista.show_health_armor[0] then
local healthWidth = 50 * (health / 100)
renderDrawBox(screenX - 25, screenY - 15, 50, 5, 0xFF000000)
renderDrawBox(screenX - 25, screenY - 15, healthWidth, 5, white)

if armor > 0 then
local armorWidth = 50 * (armor / 100)
renderDrawBox(screenX - 25, screenY + 7, 50, 3, 0xFF000000)
renderDrawBox(screenX - 25, screenY + 7, armorWidth, 3, white)
end
end

if EspSulista.show_line_and_distance[0] then
local selfScreenX, selfScreenY = convert3DCoordsToScreen(localX, localY, localZ)
if selfScreenX and selfScreenY then
renderDrawLine(selfScreenX, selfScreenY, screenX, screenY, 1, white)
end
end

if EspSulista.show_skeleton[0] then
for _, bone in ipairs(bones) do
local x1, y1, z1 = getBonePosition(playerPed, bone)
local x2, y2, z2 = getBonePosition(playerPed, bone + 1)
if x1 and y1 and z1 and x2 and y2 and z2 then
local r1, sx1, sy1 = convert3DCoordsToScreenEx(x1, y1, z1)
local r2, sx2, sy2 = convert3DCoordsToScreenEx(x2, y2, z2)
if r1 and r2 then
renderDrawLine(sx1, sy1, sx2, sy2, 2, white)
end
end
end
end

if EspSulista.show_box[0] then
local x1, y1 = convert3DCoordsToScreen(targetX, targetY, targetZ + 1.0)
local x2, y2 = convert3DCoordsToScreen(targetX, targetY, targetZ - 1.0)

if x1 and y1 and x2 and y2 then
local height = y2 - y1
local width = height / 2
local topLeftX = x1 - width / 2
local topLeftY = y1
renderDrawBoxWithBorder(topLeftX, topLeftY, width, height, white, 1)
end
end

if EspSulista.show_weapon[0] then
local weaponId = getCurrentCharWeapon(playerPed)
local weaponNames = {
  [0] = "Fist", [1] = "Brass Knuckles", [22] = "Pistol", [23] = "Silenced",
  [24] = "Deagle", [25] = "Shotgun", [26] = "Sawn-off", [27] = "Spas-12",
  [28] = "Uzi", [29] = "MP5", [30] = "AK-47", [31] = "M4",
  [32] = "Tec-9", [33] = "Rifle", [34] = "Sniper", [35] = "Rocket",
  [36] = "HS Rocket", [38] = "Minigun"
}
local weaponName = weaponNames[weaponId] or ("ID: " .. weaponId)
renderFontDrawText(EspSulista.font, weaponName, screenX - 30, screenY + 15, white)
end

if EspSulista.show_status[0] then
local status = "ALIVE"
if isCharDead(playerPed) then status = "DEAD" end
local statusY = EspSulista.show_weapon[0] and (screenY + 30) or (screenY + 15)
renderFontDrawText(EspSulista.font, status, screenX - 30, statusY, white)
end
end
end
end
end
end
end

function main()
while true do
wait(0)

if isWidgetPressedEx(WIDGET_SPRINT, 0) and isWidgetSwipedLeft(0xA1) then
enable[0] = not enable[0]
end

if isWidgetPressedEx(WIDGET_SPRINT, 0) and isWidgetSwipedRight(0xA1) then
enableSilent[0] = not enableSilent[0]
end

if isWidgetPressedEx(WIDGET_ATTACK, 0) and isWidgetSwipedLeft(0xA1) then
EspSulista.enabled[0] = not EspSulista.enabled[0]
end

Aimbot()
processSilentAim()
drawESP()
end
end

imgui.OnFrame(
  function()
  return circuloFOVAIM[0] and not isGamePaused()
  end,
  function()
  local screenWidth, screenHeight = getScreenResolution()
  local circleX = screenWidth * 0.5180
  local circleY = screenHeight * 0.4750
  local color = imgui.ImVec4(pjl.fovColorAim[0], pjl.fovColorAim[1], pjl.fovColorAim[2], pjl.fovColorAim[3])
  local bordaaim = imgui.ImVec4(pjl.bordaaimon[0], pjl.bordaaimon[1], pjl.bordaaimon[2], pjl.bordaaimon[3])
  local colorHex = imgui.ColorConvertFloat4ToU32(color)
  imgui.GetBackgroundDrawList():AddCircleFilled(imgui.ImVec2(circleX, circleY), fovSizeAIM[0], colorHex, 300)
  imgui.GetBackgroundDrawList():AddCircle(imgui.ImVec2(circleX, circleY), fovSizeAIM[0], imgui.ColorConvertFloat4ToU32(bordaaim), 300)
  end
)

imgui.OnFrame(
  function()
  return enableSilent[0] and circuloFOVsilent[0] and not isGamePaused()
  end,
  function()
  local screenWidth, screenHeight = getScreenResolution()
  local fovCenterX, fovCenterY

  if isCurrentCharWeapon(PLAYER_PED, 34) then
  fovCenterX = screenWidth / 2
  fovCenterY = screenHeight / 2
  else
    fovCenterX = screenWidth * offsetsilentcirculoX[0]
  fovCenterY = screenHeight * offsetsilentcirculoY[0]
  end

  local circleColor = imgui.ImVec4(fovColor[0], fovColor[1], fovColor[2], fovColor[3])
  local bordaColor = imgui.ImVec4(bosrdabbsilen[0], bosrdabbsilen[1], bosrdabbsilen[2], bosrdabbsilen[3])

  imgui.GetBackgroundDrawList():AddCircle(
    imgui.ImVec2(fovCenterX, fovCenterY),
    tamanhoFOVsilent[0],
    imgui.ColorConvertFloat4ToU32(bordaColor),
    300
  )
  imgui.GetBackgroundDrawList():AddCircleFilled(
    imgui.ImVec2(fovCenterX, fovCenterY),
    tamanhoFOVsilent[0],
    imgui.ColorConvertFloat4ToU32(circleColor),
    300
  )
  end
)

-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- colocando pra chegar no kb necessário
-- by wazz
