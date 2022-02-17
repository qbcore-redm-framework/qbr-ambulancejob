local QBCore = exports['qbr-core']:GetCoreObject()
local hold = 5
deathTime = 0
emsNotified = false
--[[ Functions ]]--
function OnDeath()
    if not isDead then
        isDead = true
        TriggerServerEvent("hospital:server:SetLaststandStatus", false)
        TriggerServerEvent("hospital:server:SetDeathStatus", isDead)
        TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_died'))                
    end
end

function DeathTimer()
    while isDead do
        Citizen.Wait(1000)
        deathTime = deathTime - 1
        if deathTime <= 0 then   
            if IsControlPressed(0, 0xCEFD9220) and not isInHospitalBed then
                TriggerEvent("hospital:client:RespawnAtHospital")
                return
            end
        end
    end
end

function DrawTxt(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
    local str = CreateVarString(10, "LITERAL_STRING", str)    
    SetTextScale(w, h)
    SetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    DisplayText(str, x, y)
end

--[[ Threads ]]--
CreateThread(function()
	while true do
		local player = PlayerId()     
		if Citizen.InvokeNative(0xB8DFD30D6973E135, player) then
            local playerPed = PlayerPedId()
            if GetEntityHealth(playerPed) <= 0 and not InLaststand then
                SetLaststand(true)
            end              
        elseif GetEntityHealth(playerPed) <= 0 and InLaststand and not isDead then
            deathTime = Config.DeathTime
            OnDeath()
            DeathTimer()
            SetLaststand(false)                
            local killer_2, killerWeapon = NetworkGetEntityKillerOfPlayer(player)
            local killer = GetPedSourceOfDeath(playerPed)
            if killer_2 ~= 0 and killer_2 ~= -1 then
                killer = killer_2
            end
            local killerId = NetworkGetPlayerIndexFromPed(killer)
            local killerName = killerId ~= -1 and GetPlayerName(killerId) .. " " .. "("..GetPlayerServerId(killerId)..")" or Lang:t('info.self_death')
            local weaponLabel = Lang:t('info.wep_unknown')
            local weaponName = Lang:t('info.wep_unknown')
            local weaponItem = QBCore.Shared.Weapons[killerWeapon]
            if weaponItem then
                weaponLabel = weaponItem.label
                weaponName = weaponItem.name
            end
            TriggerServerEvent("qbr-log:server:CreateLog", "death", Lang:t('logs.death_log_title', {playername = GetPlayerName(-1), playerid = GetPlayerServerId(player)}), "red", Lang:t('logs.death_log_message', {killername = killerName, playername = GetPlayerName(player), weaponlabel = weaponLabel, weaponname = weaponName}))
		end
        Citizen.Wait(1000)
	end
end)

CreateThread(function()
	while true do
        sleep = 1000
		if isDead or InLaststand then            
            sleep = 5
            local ped = PlayerPedId()            
            
            DisableAllControlActions(0)
			EnableControlAction(0, 0x9720FCEE, true)   -- T
            EnableControlAction(0, 0xCEFD9220, true)    -- E
            EnableControlAction(0, 0x760A9C6F, true)    -- G            
            
            if isDead then              
                if not isInHospitalBed then
                    if deathTime > 0 then
                        DrawTxt(Lang:t('info.respawn_txt', {deathtime = math.ceil(deathTime)}), 0.50, 0.80, 0.5, 0.5, true, 255, 0, 0, 200, true)
                    else                        
                        DrawTxt(Lang:t('info.respawn_revive', {cost = Config.BillCost}), 0.50, 0.80, 0.5, 0.5, true, 255, 0, 0, 200, true)
                    end
                end
                SetCurrentPedWeapon(ped, GetHashKey("weapon_unarmed"))           
            elseif InLaststand then
                sleep = 5

                if LaststandTime > Laststand.MinimumRevive then
                    DrawTxt(Lang:t('info.bleed_out', {time = math.ceil(LaststandTime)}), 0.50, 0.80, 0.5, 0.5, true, 255, 255, 255, 200, true)
                else
                    DrawTxt(Lang:t('info.bleed_out_help', {time = math.ceil(LaststandTime)}), 0.50, 0.80, 0.5, 0.5, true, 255, 255, 255, 200, true)
                    if not emsNotified then
                        DrawTxt(Lang:t('info.request_help'), 0.50, 0.85, 0.5, 0.5, true, 255, 255, 255, 200, true)
                    else
                        DrawTxt(Lang:t('info.help_requested'), 0.50, 0.85, 0.5, 0.5, true, 255, 255, 255, 200, true)
                    end

                    if IsControlJustPressed(0, 0x760A9C6F) and not emsNotified then
                        TriggerServerEvent('hospital:server:ambulanceAlert', Lang:t('info.civ_down'))
                        emsNotified = true
                    end
                end
            end
		end        
        Citizen.Wait(sleep)
	end
end)