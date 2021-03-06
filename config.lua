Config = {}
Config.WaitTimeAtBusStop = 8 -- In seconds
-- If you want to change this go here https://www.vespura.com/fivem/drivingstyle/
-- There are some problems with traffic lights, sometimes the vehicle takes a weird path
Config.DriveStyle = 2103615 
Config.Speed = 20.0


Config.Routes = {
	{ 	-- Route: Central Garage -> First spawn point -> Vechileshop
		info = { 
			color = 84, 
			hash = "bus",
			busNum = 4,
			timeBetweenBus = 20, -- 40
			startHeading = 68.031
		},
		busStops = {
			{ pos = vector3(234.9626, -829.2527, 29.98755), stop = true },
			{ pos = vector3(-232.1934, -983.7758, 28.60583), stop = true },
			{ pos = vector3(-68.75604, -1078.668, 26.97144), stop = true },
			{ pos = vector3(176.8747, -1030.365, 29.3136), stop = false },
			{ pos = vector3(270.3956, -848.2022, 29.33044), stop = false },
		}
	},
	--Example of new route
	{
		info = { 
			color = 24, -- Route color https://wiki.gtanet.work/index.php?title=Blips#Blip_Colors
			hash = "coach", -- hash of vehicle to use ("coach", "pbus", "pbus2" ...) https://wiki.gtanet.work/index.php?title=Vehicle_Models
			busNum = 4, -- number of buses per route (>= 1)
			timeBetweenBus = 40, -- In second (80)
			startHeading = 215.433 -- First spawn will be at first bus stop with this heading
		},
		busStops = {
			{ pos = vector3(-1167.943, -1471.187, 3.634399), stop = true },
			{ pos = vector3(-1107.257, -1467.336, 4.342163), stop = false }, -- stop = false -> the bus won't stop but is forced to pass here
			{ pos = vector3(-808.1934, -1029.653, 12.48059), stop = true },
			{ pos = vector3(-560.1099, -843.8505, 26.75244), stop = true },
			{ pos = vector3(-248.822, -881.9077, 29.95386), stop = true },
			{ pos = vector3(194.5978, -789.3494, 30.96484), stop = true },
			{ pos = vector3(131.578, -578.3077, 43.07983), stop = false },
			{ pos = vector3(-757.6219, -936.4088, 17.33337), stop = true },
		}
	},
}
