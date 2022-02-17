local QBCore = exports['qbr-core']:GetCoreObject()
local statusCheckPed = nil
local PlayerJob = {}
local onDuty = false
local currentGarage = 1
local reviveDict = "mini_games@story@mob4@heal_jules@bandage@arthur"
local reviveAnim = "bandage_loop"
local woundsDict = "mini_games@story@mob4@heal_jules@bandage@arthur"
local woundsAnim = "bandage_loop"
metaAnim = false

--[[ Functions ]]--

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
	end
	return closestPlayer, closestDistance
end

local function DrawText3D(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)

    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end

function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]
    QBCore.Functions.SpawnVehicle(vehicleInfo, function(veh)
        SetEntityHeading(veh, coords.w)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        if Config.VehicleSettings[vehicleInfo] ~= nil then
            QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
        end
    end, coords, true)
end

function MenuGarage()
    local vehicleMenu = {
        {
            header = Lang:t('menu.amb_vehicles'),
            isMenuHeader = true
        }
    }

    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]
    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu+1] = {
            header = label,
            txt = "",
            params = {
                event = "ambulance:client:TakeOutVehicle",
                args = {
                    vehicle = veh
                }
            }
        }
    end
    vehicleMenu[#vehicleMenu+1] = {
        header = Lang:t('menu.close'),
        txt = "",
        params = {
            event = "qbr-menu:client:closeMenu"
        }

    }
    exports['qbr-menu']:openMenu(vehicleMenu)
end

function createAmbuPrompts()
    for k, v in pairs(Config.Locations["armory"]) do
        exports['qbr-prompts']:createPrompt("ambulance:armory:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'Armory', {
            type = 'client',
            event = 'ambulance:client:promptArmory',
        })
    end
    for k, v in pairs(Config.Locations["duty"]) do
        exports['qbr-prompts']:createPrompt("ambulance:duty:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'On/Off Duty', {
            type = 'client',
            event = 'ambulance:client:promptDuty',
        })        
    end
    for k, v in pairs(Config.Locations["vehicle"]) do
        exports['qbr-prompts']:createPrompt("ambulance:vehicle:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'Jobgarage', {
            type = 'client',
            event = 'ambulance:client:promptVehicle',
            args = {k},
        }) 
    end    
    for k, v in pairs(Config.Locations["stash"]) do
        exports['qbr-prompts']:createPrompt("ambulance:stash:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'Personal Stash', {
            type = 'client',
            event = 'ambulance:client:promptStash',
        })        
    end    
    for k, v in pairs(Config.Locations["checking"]) do
        exports['qbr-prompts']:createPrompt("ambulance:checkin:"..k, vector3(v.x, v.y, v.z), Config.PromptKey, 'Check-in', {
            type = 'client',
            event = 'ambulance:client:promptCheckin',
        })        
    end
    for k, v in pairs(Config.Locations["beds"]) do
        exports['qbr-prompts']:createPrompt("ambulance:bed:"..k, vector3(Config.Locations["beds"][k].coords.x, Config.Locations["beds"][k].coords.y, Config.Locations["beds"][k].coords.z), Config.PromptKey, Lang:t('text.lie_bed', {cost=Config.BillCost}), {
            type = 'client',
            event = 'ambulance:client:promptBed',
        })
    end        
end

--[[ Events ]]--
RegisterNetEvent('ambulance:client:promptArmory', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == "ambulance"  then
            TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
        else
            QBCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)    
end)

RegisterNetEvent('ambulance:client:promptDuty', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == "ambulance"  then
            onDuty = not onDuty
            TriggerServerEvent("QBCore:ToggleDuty")
        else
            QBCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)    
end)

RegisterNetEvent('ambulance:client:promptVehicle', function(k)
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == "ambulance"  then
            if IsPedInAnyVehicle(ped, false) then
                QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(ped))
            else
                MenuGarage()
                currentGarage = k
            end
        else
            QBCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)    
end)

RegisterNetEvent('ambulance:client:promptStash', function(k)
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == "ambulance"  then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_"..QBCore.Functions.GetPlayerData().citizenid)
            TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_"..QBCore.Functions.GetPlayerData().citizenid)
        else
            QBCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
        end
    end)    
end)

RegisterNetEvent('ambulance:client:TakeOutVehicle', function(data)
    local vehicle = data.vehicle
    TakeOutVehicle(vehicle)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    TriggerServerEvent("hospital:server:SetDoctor")
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)    
    TriggerServerEvent("hospital:server:SetDoctor")
    
    local ped = PlayerPedId()
    local player = PlayerId()    
    CreateThread(function()
        --Setting default Health Stats
        Citizen.Wait(1000)        
        Citizen.InvokeNative(0x166E7CF68597D8B5, ped, 200) --SetEntityMaxHealth(ped, 750)

        SetEntityHealth(ped, GetEntityMaxHealth(ped)) -- Healthbar 100%
        Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, 1, 1, true) -- Staminabar 100%

        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 0, 100) -- Healthcore
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 1, 100) -- Staminacore
        Citizen.InvokeNative(0xC6258F41D86676E0, ped, 2, 100) -- DeadEYEcore

        SetPlayerHealthRechargeMultiplier(player, 0.1)

        -- Check if player logged out dead/inlaststand
        QBCore.Functions.GetPlayerData(function(PlayerData)
            PlayerJob = PlayerData.job
            onDuty = PlayerData.job.onduty
            -- Set death
            if (not PlayerData.metadata["inlaststand"] and PlayerData.metadata["isdead"]) then
                deathTime = Laststand.ReviveInterval
                SetEntityHealth(PlayerPedId(), 0)
                OnDeath()
                DeathTimer()
            -- set Laststand
            elseif (PlayerData.metadata["inlaststand"] and not PlayerData.metadata["isdead"]) then
                SetEntityHealth(PlayerPedId(), 0)
                SetLaststand(true)
            else
                TriggerServerEvent("hospital:server:SetDeathStatus", false)
                TriggerServerEvent("hospital:server:SetLaststandStatus", false)
            end
            createAmbuPrompts()            
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
    TriggerServerEvent("hospital:server:SetDoctor")
end)

RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 3.0 then
        local playerId = GetPlayerServerId(player)
        statusCheckPed = GetPlayerPed(player)
        QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
            if result then
                for k, v in pairs(result) do
                    if k ~= "BLEED" and k ~= "WEAPONWOUNDS" then
                        statusChecks[#statusChecks+1] = {bone = Config.BoneIndexes[k], label = v.label .." (".. Config.WoundStates[v.severity] ..")"}
                    elseif k ~= "BLEED" and k =="WEAPONWOUNDS" then
                        for i, c in pairs(v) do                        
                            print("I: "..tostring(i))
                            print("C: "..tostring(c))
                            QBCore.Functions.Notify(Lang:t('info.status')..tostring(WeaponDamageList[c]), 'success')
                        end
                    elseif k ~= "WEAPONWOUNDS" and k =="BLEED" then
                        QBCore.Functions.Notify(Lang:t('info.is_staus', {status = Config.BleedingStates[result["BLEED"]].label}), 'success')
                    else
                        QBCore.Functions.Notify(Lang:t('success.healthy_player'), 'success')
                    end
                end
                isStatusChecking = true
                statusCheckTime = Config.CheckTime
            end
        end, playerId)
    else
        QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
    end
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            local player, distance = GetClosestPlayer()
            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)
                isHealingPerson = true
                QBCore.Functions.Progressbar("hospital_revive", Lang:t('progress.revive'), 5000, false, true, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = reviveDict,
                    anim = reviveAnim,
                    flags = 1,
                }, {}, {}, function() -- Done
                    StopAnimTask(PlayerPedId(), reviveDict, reviveAnim, 1.0)
                    isHealingPerson = false
                    QBCore.Functions.Notify(Lang:t('success.revived'), 'success')
                    TriggerServerEvent("hospital:server:RevivePlayer", playerId)
                end, function() -- Cancel
                    StopAnimTask(PlayerPedId(), reviveDict, reviveAnim, 1.0)
                    isHealingPerson = false
                    QBCore.Functions.Notify(Lang:t('error.cancled'), "error")
                end)
            else
                QBCore.Functions.Notify(Lang:t('error.no_player'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.no_firstaid'), "error")
        end
    end, 'firstaid')
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            local player, distance = GetClosestPlayer()
            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)
                isHealingPerson = true
                QBCore.Functions.Progressbar("hospital_healwounds", Lang:t('progress.healing'), 5000, false, true, {
                    disableMovement = true,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = woundsDict,
                    anim = woundsAnim,
                    flags = 1,
                }, {}, {}, function() -- Done
                    StopAnimTask(PlayerPedId(), woundsDict, woundsAnim, 1.0)
                    isHealingPerson = false
                    QBCore.Functions.Notify(Lang:t('success.helped_player'), 'success')
                    TriggerServerEvent("hospital:server:TreatWounds", playerId)
                end, function() -- Cancel
                    StopAnimTask(PlayerPedId(), woundsDict, woundsAnim, 1.0)
                    isHealingPerson = false
                    QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
                end)
            else
                QBCore.Functions.Notify(Lang:t('error.no_player'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.no_bandage'), "error")
        end
    end, 'bandage')
end)

--[[ Threads ]]--
CreateThread(function()
    while true do
        Wait(10)
        if isStatusChecking then
            for k, v in pairs(statusChecks) do
                local x,y,z = table.unpack(GetPedBoneCoords(statusCheckPed, v.bone))
                DrawText3D(x, y, z, v.label)
            end
        end
    end
end)
