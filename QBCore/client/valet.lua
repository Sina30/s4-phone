local enroute = false
local mechPed = nil

function setCars(cars)
    SendNUIMessage({event = 'updateCars', cars = cars})
end

RegisterNUICallback('getCars', function(data)
    QBCore.TriggerCallback('s4-phone:getCars', function(data)
        for i = 1, #data do
            model = GetDisplayNameFromVehicleModel(data[i]["props"].model)
            data[i]["props"].model = model
        end
        setCars(data)
    end)
end)

RegisterNUICallback('ValeCagir', function(data)
  TriggerServerEvent("s4-phone:PlakadanBilgi", data.plaka)
  --print(data.plaka)
end)


RegisterNetEvent("s4-phone:AracSpawn")
AddEventHandler("s4-phone:AracSpawn", function(veri)
--    if enroute then
--       ESX.ShowNotification(_U('valet_wait'))
--        return
--    end

    local data = {}
	data.props = json.decode(veri)
    local gameVehicles = QBCore.Fucntions.GetVehicles()
    print("SA   "..data.props.plate)
	for i = 1, #gameVehicles do
		local vehicle = gameVehicles[i]

        if DoesEntityExist(vehicle) then
            if QBCore.Functions.Trim(GetVehicleNumberPlateText(vehicle)) ==QBCore.Functions.Trim(data.props.plate) then
                local vehicleCoords = GetEntityCoords(vehicle)
                SetNewWaypoint(vehicleCoords.x, vehicleCoords.y)
                QBCore.Functions.Notify("Vale zaten dışarıda", "error")
				return
			end
        end
    end

    TriggerServerEvent("s4-phone:valet-car-set-outside", data.props.plate)
    
    local player = PlayerPedId()
    local playerPos = GetEntityCoords(player)

    local driverhash = 999748158
    local vehhash = data.props.model

    while not HasModelLoaded(driverhash) and RequestModel(driverhash) or not HasModelLoaded(vehhash) and RequestModel(vehhash) do
        RequestModel(driverhash)
        RequestModel(vehhash)
        Citizen.Wait(0)
    end

    SpawnVehicle(playerPos.x, playerPos.y, playerPos.z, vehhash, driverhash, data.props)
end)


function SpawnVehicle(x, y, z, vehhash, driverhash, props)                                                     --Spawning Function
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(x + math.random(-100, 100), y + math.random(-100, 100), z, 0, 3, 0)

    QBCore.Functions.SpawnVehicle(vehhash, spawnPos, spawnHeading, function(callback_vehicle)
        SetVehicleHasBeenOwnedByPlayer(callback_vehicle, true)
        
        SetEntityAsMissionEntity(callback_vehicle, true, true)
        ClearAreaOfVehicles(GetEntityCoords(callback_vehicle), 5000, false, false, false, false, false);  
        SetVehicleOnGroundProperly(callback_vehicle)
        QBCore.Functions.SetVehicleProperties(callback_vehicle, props)
        
        mechPed = CreatePedInsideVehicle(callback_vehicle, 26, driverhash, -1, true, false)              		--Driver Spawning.
        
        mechBlip = AddBlipForEntity(callback_vehicle)                                                        	--Blip Spawning.
        SetBlipFlashes(mechBlip, true)  
        SetBlipColour(mechBlip, 5)

        GoToTarget(x, y, z, callback_vehicle, mechPed, vehhash)
    end)                          --Car Spawning.
end

function GoToTarget(x, y, z, vehicle, driver, vehhash, target)
    enroute = true
    while enroute do
        Citizen.Wait(500)
        local player = PlayerPedId()
        local playerPos = GetEntityCoords(player)
        SetDriverAbility(driver, 1.0)        -- values between 0.0 and 1.0 are allowed.
        SetDriverAggressiveness(driver, 0.0)
        TaskVehicleDriveToCoord(driver, vehicle, playerPos.x, playerPos.y, playerPos.z, 20.0, 0, vehhash, 4457279, 1, true)
        local distanceToTarget = #(playerPos - GetEntityCoords(vehicle))
        if distanceToTarget < 15 or distanceToTarget > 150 then
            RemoveBlip(mechBlip)
            TaskVehicleTempAction(driver, vehicle, 27, 6000)
            --SetVehicleUndriveable(vehicle, true)
            SetEntityHealth(mechPed, 2000)
            GoToTargetWalking(x, y, z, vehicle, driver)
            enroute = false
        end
    end
end

function GoToTargetWalking(x, y, z, vehicle, driver)
    Citizen.Wait(500)
    TaskWanderStandard(driver, 10.0, 10)
    TriggerServerEvent('s4-phone:finish')
    Citizen.Wait(35000)
    DeletePed(mechPed)
    mechPed = nil
end