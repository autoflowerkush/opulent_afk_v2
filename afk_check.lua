local afkTime = 1800 -- Time in seconds (30 minutes) before a player is considered AFK
local warningTime = 60 -- Time in seconds before a player is teleported
local checkingInterval = 30 -- Time in seconds between AFK checks

local afkPlayers = {} -- Table to track AFK players and their last action time
local warnedPlayers = {} -- Table to track players who have been warned
local teleportedPlayers = {} -- Table to track players who have been teleported

local teleportLocation = vector3(306.6802, -905.6727, 29.2937) -- Define the location where AFK players should be teleported

local function CalculateDistanceSquared(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return dx * dx + dy * dy + dz * dz
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(checkingInterval * 1000) -- Wait for the specified interval
        
        for _, playerId in ipairs(GetPlayers()) do
            local playerPed = GetPlayerPed(playerId)
            local playerCoords = GetEntityCoords(playerPed, false)
            
            -- Calculate player movement distance
            local lastCoords = afkPlayers[playerId]
            local movementDistanceSquared = 0
            if lastCoords then
                movementDistanceSquared = CalculateDistanceSquared(lastCoords.x, lastCoords.y, lastCoords.z, playerCoords.x, playerCoords.y, playerCoords.z)
            end
            
            if movementDistanceSquared <= 1.0 then -- Adjust the threshold as needed
                if afkPlayers[playerId] == nil then
                    afkPlayers[playerId] = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z, timestamp = GetGameTimer() } -- Store the last known coordinates
                elseif not teleportedPlayers[playerId] and GetGameTimer() - afkPlayers[playerId].timestamp >= afkTime * 1000 then
                    -- Teleport the player to the defined location
                    SetEntityCoords(playerPed, teleportLocation.x, teleportLocation.y, teleportLocation.z, true, true, true, false)
                    teleportedPlayers[playerId] = true
                elseif not warnedPlayers[playerId] and GetGameTimer() - afkPlayers[playerId].timestamp >= (afkTime - warningTime) * 1000 then
                    -- Warn the player only once
                    warnedPlayers[playerId] = true
                    TriggerClientEvent('chatMessage', playerId, "^1WARNING: ^7You will be teleported in 1 minute for being AFK if you don't move.")
                end
            else
                afkPlayers[playerId] = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z, timestamp = GetGameTimer() } -- Update last known coordinates
                warnedPlayers[playerId] = nil -- Reset warning status when player moves
                teleportedPlayers[playerId] = nil -- Reset teleport status when player moves
            end
        end
    end
end)
