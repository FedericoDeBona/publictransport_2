vehicles = {}
players = 0 

Citizen.CreateThread(function()
	while players == 0 do 
		Wait(1000)
	end
	for routeId, v in ipairs(Config.Routes) do
		Citizen.CreateThread(function()
			for i=1, v.info.busNum do
				StartNewRoute(routeId)
				Wait(v.info.timeBetweenBus*1000)
			end
		end)
	end
end)

function StartNewRoute(routeId)
	local route = Config.Routes[routeId]
	repeat
		Wait(0)
	until SpawnVehicle(route.info.hash, route.busStops[1].pos, route.info.startHeading, routeId)
end

function SpawnVehicle(hash, position, heading, routeId)
	local vehicle = CreateVehicle(GetHashKey(hash), position, heading, true, false)
	local attempts = 0
	repeat
		Wait(10)
		attempts = attempts + 1
		if attempts >= 25 then 
			while DoesEntityExist(vehicle) do
				DeleteEntity(vehicle)
				Wait(0)
			end
			return false 
		end
	until DoesEntityExist(vehicle)

	SetEntityDistanceCullingRadius(vehicle, 999999999.0)
	Wait(50)
	
	local ped = CreatePedInsideVehicle(vehicle, 0, GetHashKey("s_m_m_gentransport"), -1, true, false)
	attempts = 0
	repeat
		Wait(10)
		attempts = attempts + 1
		if attempts >= 25 then 
			repeat
				DeleteEntity(vehicle)
				Wait(0)
			until not DoesEntityExist(vehicle)
			return false
		end
	until DoesEntityExist(ped)

	SetEntityDistanceCullingRadius(ped, 999999999.0)
	Wait(50)

	if DoesEntityExist(ped) and DoesEntityExist(vehicle) then
		local target = NetworkGetEntityOwner(ped)
		local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
		local pedNetId = NetworkGetNetworkIdFromEntity(ped)
		if vehicles[target] == nil then
			vehicles[target] = {}
		end
		table.insert(vehicles[target], {vehicleNetId = vehicleNetId, pedNetId = pedNetId, routeId = routeId, nextStop = 2, color = Config.Routes[routeId].info.color})
		TriggerClientEvent("publictransport:setupDriver", target, pedNetId, vehicleNetId, routeId)
		TriggerClientEvent("publictransport:addBlipForVehicle", -1, vehicleNetId, Config.Routes[routeId].info.color)
		return true
	end
end

AddEventHandler('playerDropped', function (reason)
	local src = source
	if vehicles[src] ~= nil then
		players = players-1
		if players > 0 then
			for i, data in ipairs(vehicles[src]) do
				ManageOwnerChanged(src, data.pedNetId, data.vehicleNetId)
			end
		else
			CleanUp()
		end
	end
end)

AddEventHandler("onResourceStop", function(resName)
	if GetCurrentResourceName() == resName then
		CleanUp()
	end
end)

RegisterNetEvent("publictransport:updateNextStop")
AddEventHandler("publictransport:updateNextStop", function(pedNetId, vehicleNetId, nextStop)
	local s = source
	if vehicles[s] == nil then
		return
	end
	local index = FindRouteInTable(s, pedNetId)
	if index ~= -1 then
		vehicles[s][index].nextStop = nextStop
	end	
end)

RegisterNetEvent("publictransport:onPlayerSpawn")
AddEventHandler("publictransport:onPlayerSpawn", function()
	local s = source
	players = players+1
	SetPlayerCullingRadius(s, 999999999.0)
	TriggerClientEvent("publictransport:forceSetAllVehicleBlips", s, vehicles)
end)

RegisterCommand("empty", function()
	for _, vehicle in ipairs(GetAllVehicles()) do
		DeleteEntity(vehicle)
	end
	for _, ped in ipairs(GetAllPeds()) do
		if not IsPedAPlayer(ped) then
			DeleteEntity(ped)
		end
	end
end)

RegisterNetEvent("publictransport:ownerChanged")
AddEventHandler("publictransport:ownerChanged", function(pedNetId, vehicleNetId)
	local src = source
	if vehicles[src] ~= nil then
		ManageOwnerChanged(src, pedNetId, vehicleNetId)
	end
end)

function ManageOwnerChanged(src, pedNetId, vehicleNetId)
	local target
	local attempts = 0
	ClearPedTasks(NetworkGetEntityFromNetworkId(pedNetId))

	if NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(pedNetId)) ~= src then
		target = NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(pedNetId))
	elseif NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(vehicleNetId)) ~= src then
		target = NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(vehicleNetId))
	end

	-- target = -1 mean server owning it, target = nil no idea why it happends
	if target == nil or target == -1 then
		Wait(100)
		ManageOwnerChanged(src, pedNetId, vehicleNetId)
		return
	end
	local index = FindRouteInTable(src, pedNetId)
	if index ~= -1 then
		if vehicles[target] == nil then
			vehicles[target] = {}
		end
		local v = vehicles[src][index]
		local vehicleNetId = v.vehicleNetId
		local pedNetId = v.pedNetId
		local routeId = v.routeId
		local nextStop = v.nextStop
		local color = v.color
		table.insert(vehicles[target], {vehicleNetId = vehicleNetId, pedNetId = pedNetId, routeId = routeId, nextStop = nextStop, color = v.cloro})
		table.remove(vehicles[src], index)
		TriggerClientEvent("publictransport:restoreRoute", target, pedNetId, vehicleNetId, routeId, nextStop)
	end
	return
end


function CleanUp()
	for id, playerData in pairs(vehicles) do
		for i,data in ipairs(playerData) do
			local veh = NetworkGetEntityFromNetworkId(data.vehicleNetId)
			local ped = NetworkGetEntityFromNetworkId(data.pedNetId)
			if DoesEntityExist(veh) and DoesEntityExist(ped) then
				DeleteEntity(veh)
				DeleteEntity(ped)
			end
		end
	end
	vehicles = {}
	players = 0
end

function FindRouteInTable(src, pedNetId)
	for i, data in ipairs(vehicles[src]) do
		if data.pedNetId == pedNetId then
			return i
		end
	end
	return -1
end
