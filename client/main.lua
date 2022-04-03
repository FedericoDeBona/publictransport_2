-- ================================================================================
-- make your script migration-aware instead of trying to stop migration | d-bubble
-- ================================================================================

firstSpawn = true
threadId = nil
ownership = {}

Citizen.CreateThread(function()
	-- If you want to restart the resource in game uncomment next line
	-- TriggerEvent("playerSpawned")

	for _, route in ipairs(Config.Routes) do
		for _, curr in ipairs(route.busStops) do
			if curr.stop == true then  
				local blip = AddBlipForCoord(curr.pos)

				SetBlipSprite (blip, 513)
				SetBlipColour (blip, route.info.color)
				SetBlipScale(blip, 0.5)
				SetBlipAsShortRange(blip, true)
			
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName("Bus stop")
				EndTextCommandSetBlipName(blip)
			end
		end
	end
end)

RegisterNetEvent("publictransport:setupDriver")
AddEventHandler("publictransport:setupDriver", function(pedNetId, vehicleNetId, routeId)
	DoRequestNetControl(pedNetId)
	DoRequestNetControl(vehicleNetId)
	Wait(100)
	StartOwnershipCheck(pedNetId, vehicleNetId)

	local vehicle = NetToVeh(vehicleNetId)
	local ped = NetToPed(pedNetId)

	LoadCollision(ped, vehicle)
	SetVehicleOnGroundProperly(vehicle, 5.0)

	-- stop netIDs from changing
	NetworkUseHighPrecisionBlending(pedNetId, false)
	NetworkUseHighPrecisionBlending(vehicleNetId, false)

	SetupPedAndVehicle(ped, vehicle)

	DoDriverJob(ped, vehicle, routeId, 2)
end)

function DoDriverJob(ped, vehicle, routeId, busStop)
	while not ownership[pedNetId] do 
		local pedNetId = PedToNet(ped)
		local routeInfo = Config.Routes[routeId].busStops[busStop]
		local coords = routeInfo.pos
		ClearPedTasks(ped)
		ForceEntityAiAndAnimationUpdate(ped)
		
		repeat 
			if ownership[pedNetId] then return end
			SetVehicleOnGroundProperly(vehicle, 5.0)
			TaskVehicleDriveToCoordLongrange(ped, vehicle, coords, Config.Speed*1.0, Config.DriveStyle, 18.0)
			DoStuckCheck(vehicle)
			Wait(1500)
		until GetScriptTaskStatus(ped, 567490903) > 1 or GetEntitySpeed(vehicle) > 1.0
		while GetScriptTaskStatus(ped, 567490903) ~= 7 do
			if ownership[pedNetId] then return end		
			DoStuckCheck(vehicle)
			Wait(100)
		end
		if routeInfo.stop == true then
			LoadCollision(ped, vehicle)
			TaskVehiclePark(ped, vehicle, coords, GetEntityHeading(vehicle), 1, 20.0, true)
			local timer = GetGameTimer()
			local exit = true
			while GetScriptTaskStatus(ped, -272084098) ~= 7 and exit do
				if ownership[pedNetId] then return end
				if GetGameTimer() - timer > 10000 then
					exit = false
					ClearPedTasks(ped)
				end
				Wait(100)
			end		
			Wait(Config.WaitTimeAtBusStop*1000)
		end
		if ownership[pedNetId] then return end
		busStop = ((busStop+1) > #Config.Routes[routeId].busStops) and 1 or (busStop+1)
		TriggerServerEvent("publictransport:updateNextStop", PedToNet(ped), VehToNet(vehicle), busStop)
	end
end

-- Uncomment this if you want to remove all veh/peds
--[[
Citizen.CreateThread(function()
	for i = 1, 15 do
		EnableDispatchService(i, false)
	end
	SetMaxWantedLevel(0)
	while true do
		SetPedDensityMultiplierThisFrame(0.0)
		SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)

		-- Traffic Intensity
		SetRandomVehicleDensityMultiplierThisFrame(0.0)
		SetParkedVehicleDensityMultiplierThisFrame(0.0)
		-- Vehicles on streets 0.0 - 1.0
		SetVehicleDensityMultiplierThisFrame(0.0)
		Wait(0)
	end
end)
]]

AddEventHandler("playerSpawned", function(spawnInfo)
	if firstSpawn then
		TriggerServerEvent("publictransport:onPlayerSpawn")
		firstSpawn = false
	end
end)

RegisterNetEvent("publictransport:addBlipForVehicle")
AddEventHandler("publictransport:addBlipForVehicle", function(vehicleNetId, color)
	if firstSpawn then return end
	while not NetworkDoesNetworkIdExist(vehicleNetId) do Wait(0) end
	local vehicle = NetToVeh(vehicleNetId)
	local blip = AddBlipForEntity(vehicle)
	SetBlipSprite(1, 463)
	SetBlipColour(blip, color)
	SetBlipScale(blip, 0.5)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName("Bus " .. color)
	EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent("publictransport:restoreRoute")
AddEventHandler("publictransport:restoreRoute", function(pedNetId, vehicleNetId, routeId, nextStop)
	DoRequestNetControl(pedNetId)
	DoRequestNetControl(vehicleNetId)
	while not NetworkHasControlOfNetworkId(pedNetId) or not NetworkHasControlOfNetworkId(vehicleNetId) do Wait(0) end
	StartOwnershipCheck(pedNetId, vehicleNetId)
	local vehicle = NetToVeh(vehicleNetId)
	local ped = NetToPed(pedNetId)
	if DoesEntityExist(ped) and DoesEntityExist(vehicle) then
		LoadCollision(ped, vehicle)
		ClearPedTasks(ped)
		SetupPedAndVehicle(ped, vehicle)
		DoDriverJob(ped, vehicle, routeId, nextStop)
	end
end)

RegisterNetEvent("publictransport:forceSetAllVehicleBlips")
AddEventHandler("publictransport:forceSetAllVehicleBlips", function(vehiclesList)
	for id, playerData in pairs(vehiclesList) do
		for i,data in ipairs(playerData) do
			while not NetworkDoesNetworkIdExist(data.vehicleNetId) do Wait(0) end
			local vehicle = NetToVeh(data.vehicleNetId)
			if DoesEntityExist(vehicle) then
				local blip = AddBlipForEntity(vehicle)
				SetBlipSprite(1, 463)
				SetBlipColour(blip, data.color)
				SetBlipScale(blip, 0.5)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName("Bus " .. data.color)
				EndTextCommandSetBlipName(blip)
			end
		end
	end
end)

function StartOwnershipCheck(pedNetId, vehicleNetId)
	ownership[pedNetId] = false
	Citizen.CreateThread(function()
		while true do
			Wait(0)
			if not NetworkHasControlOfNetworkId(pedNetId) then
				ownership[pedNetId] = true
				TriggerServerEvent("publictransport:ownerChanged", pedNetId, vehicleNetId)
				return
			end
		end
	end)
end

function LoadCollision(ped, vehicle)
	SetEntityLoadCollisionFlag(ped, true, 1)
	SetEntityLoadCollisionFlag(vehicle, true, 1)
	while not HasCollisionLoadedAroundEntity(vehicle) or not HasCollisionLoadedAroundEntity(ped) do Wait(0) end
end

function DoRequestNetControl(netId)
	if NetworkDoesNetworkIdExist(netId) then
		while not NetworkHasControlOfNetworkId(netId) do 
			NetworkRequestControlOfNetworkId(netId)
			Wait(0)
		end
	end
end

function SetupPedAndVehicle(ped, vehicle)
	SetEntityCanBeDamaged(vehicle, false)
	SetVehicleDamageModifier(vehicle, 0.0)
	SetVehicleEngineCanDegrade(vehicle, false)
	SetVehicleEngineOn(vehicle, true, true, false)
	SetVehicleLights(vehicle, 0)
	-- Not sure but this should make the driver able to set vehicle on wheels again (like players can do when vehicle goes upside down)
	if not DoesVehicleHaveStuckVehicleCheck(vehicle) then
		AddVehicleStuckCheckWithWarp(vehicle, 10.0, 1000, false, false, false, -1)
	end
	SetEntityCanBeDamaged(ped, false)
	SetPedCanBeTargetted(ped, false)
	SetDriverAbility(ped, 1.0)
	SetDriverAggressiveness(ped, 0.0)
	SetBlockingOfNonTemporaryEvents(ped, true)
	SetPedConfigFlag(ped, 251, true)
	SetPedConfigFlag(ped, 64, true)
	SetPedStayInVehicleWhenJacked(ped, true)
	SetPedCanBeDraggedOut(ped, false)
	SetEntityCleanupByEngine(ped, false)
	SetEntityCleanupByEngine(vehicle, false)
	SetPedComponentVariation(ped, 3, 1, 2, 0)
	SetPedComponentVariation(ped, 4, 0, 2, 0)
end

-- Check if vehicle is stuck while driving, if so tp it to the closest road
function DoStuckCheck(vehicle)
	if IsVehicleStuckTimerUp(vehicle, 0, 7000) or IsVehicleStuckTimerUp(vehicle, 1, 7000) or IsVehicleStuckTimerUp(vehicle, 2, 7000) or IsVehicleStuckTimerUp(vehicle, 2, 7000) then
		SetEntityCollision(vehicle, false, true)
		local vehPos = GetEntityCoords(vehicle)
		local ret, pos = GetClosestRoad(vehPos.x, vehPos.y, vehPos.z, 1.0, 1, false)
		if ret then
			SetEntityCoords(vehicle, pos)
			vehPos = GetEntityCoords(vehicle)
			local ret2, pos2, heading = GetClosestVehicleNodeWithHeading(vehPos.x, vehPos.y, vehPos.z, 1, 3.0, 0)
			if ret2 then
				SetEntityHeading(vehicle, heading)
				SetEntityCollision(vehicle, true, true)
			end
		end
	end
end

-- RegisterCommand("tpgarage", function()
-- 	SetEntityCoords(PlayerPedId(), vector3(234.9626, -829.2527, 29.98755))
-- end)