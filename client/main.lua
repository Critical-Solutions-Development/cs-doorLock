local doorMenu
local DoorList = {}


AddEventHandler("cs-doorLock:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
    Logger = exports["mythic-base"]:FetchComponent("Logger")
    Chat = exports["mythic-base"]:FetchComponent("Chat")
    Menu = exports["mythic-base"]:FetchComponent("Menu")
    Notification = exports["mythic-base"]:FetchComponent("Notification")
end

AddEventHandler('Core:Shared:Ready', function()
    exports["mythic-base"]:RequestDependencies("Doors", {
        "Logger",
        "Chat",
        "Menu",
        "Notification"
    }, function(error)
        if #error > 0 then return end
        RetrieveComponents()
    end)
end)

-- Draw 3D Text Above Doors
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local scale = 0.35

    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Function to Get Closest Door
function GetClosestDoor()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestDoor, closestDist

    for _, entity in ipairs(GetGamePool("CObject")) do
        if IsDoorEntity(entity) then
            local entityCoords = GetEntityCoords(entity)
            local dist = #(playerCoords - entityCoords)

            if not closestDist or dist < closestDist then
                closestDoor = entity
                closestDist = dist
            end
        end
    end

    return closestDoor
end


function IsDoorEntity(entity)
    if not DoesEntityExist(entity) then return false end

    local model = GetEntityModel(entity)

    -- Ensure it's an object (doors are objects in FiveM)
    if GetEntityType(entity) ~= 3 then
        return false
    end

    -- Check if the object has door-like properties
    if DoorSystemGetDoorState(model) ~= nil then
        return true
    end

    return false
end

-- Function to Handle Door Selection
function WaitForDoorSelection(doorConfig)
    Citizen.CreateThread(function()
        local selectedDoor
        while true do
            Citizen.Wait(0)
            local doorEntity = GetClosestDoor()

            if doorEntity then
                local coords = GetEntityCoords(doorEntity)
                local model = GetEntityModel(doorEntity)

                -- Draw Red Marker on Door
                DrawMarker(1, coords.x, coords.y, coords.z + 1.0, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 255, 0, 0, 150, false, true, 2, nil, nil, false)

                -- Show Door Info in 3D Text
                DrawText3D(coords.x, coords.y, coords.z + 1.2, string.format("Model: %s\nCoords: %.2f, %.2f, %.2f\nPress [E] to Select", model, coords.x, coords.y, coords.z))

                -- Select Door on Key Press (E)
                if IsControlJustPressed(0, 38) then
                    selectedDoor = doorEntity
                    break
                end
            else
                -- Display "No Door Found"
                DrawText3D(GetEntityCoords(PlayerPedId()).x, GetEntityCoords(PlayerPedId()).y, GetEntityCoords(PlayerPedId()).z + 1.0, "~r~No valid door detected!")
            end
        end

        -- Apply Selected Door Data
        if selectedDoor then
            local coords = GetEntityCoords(selectedDoor)
            local model = GetEntityModel(selectedDoor)

            doorConfig.model = model
            doorConfig.coords = { x = coords.x, y = coords.y, z = coords.z }

            SaveDoorConfig(doorConfig)
            Notification:Success("Door saved successfully!", 3500, "check-circle")
        else
            Notification:Error("No door selected!", 3500, "times-circle")
        end
    end)
end


function SaveDoorConfig(door)
    local lockedValue = door.locked and 'true' or 'false'
    local specialValue = door.special and 'true' or 'false'
    local restrictionsFormatted = {}

    for _, restriction in ipairs(door.restricted) do
        if restriction.type == "job" then
            -- Safely check if workplace is empty or nil and assign properly
            local workplaceRaw = restriction.workplace
            local workplaceValue

            if workplaceRaw == nil or workplaceRaw == '' or workplaceRaw == false then
                workplaceValue = 'false'
            else
                workplaceValue = string.format("'%s'", workplaceRaw)
            end

            local jobPermissionValue = restriction.jobPermission and 'true' or 'false'
            local reqDutyValue = restriction.reqDuty and 'true' or 'false'

            table.insert(restrictionsFormatted, string.format(
                "{ type = '%s', job = '%s', workplace = %s, gradeLevel = %d, jobPermission = %s, reqDuty = %s }",
                restriction.type, restriction.job, workplaceValue, restriction.gradeLevel or 0, jobPermissionValue, reqDutyValue
            ))
        elseif restriction.type == "RealHouse" then
            table.insert(restrictionsFormatted, string.format(
                "{ type = '%s', HouseName = '%s' }", restriction.type, restriction.HouseName
            ))
        end
    end

    local newDoorData = string.format([[ 
        {
            id = "%s",
            model = %s,
            coords = vector3(%s, %s, %s),
            locked = %s,
            special = %s,
            double = %s,
            rate = 6.0,
            restricted = { %s }
        },
    ]],
        door.id,
        door.model,
        door.coords.x, door.coords.y, door.coords.z,
        lockedValue,
        specialValue,
        door.double and '"' .. door.double .. '"' or 'nil',
        table.concat(restrictionsFormatted, ", ")
    )

    TriggerServerEvent('cs-doorLock:saveConfig', newDoorData)
    Notification:Success('Door configuration saved!', 3500, 'check-circle')
end



-- Command to Open the Menu
RegisterNetEvent('cs-doorLock:openMenu')
AddEventHandler('cs-doorLock:openMenu', function()
    OpenDoorConfigMenu()
end)