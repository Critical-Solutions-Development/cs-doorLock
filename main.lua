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


-- Door Configuration Menu
function OpenDoorConfigMenu()
    local doorConfig = {
        id = "door_" .. math.random(1000, 9999),
        model = nil,
        coords = nil,
        locked = true,
        double = nil,
        restricted = {},  -- Initially no restrictions
    }

    local doorMenu = Menu:Create('doorMenu', 'Door Configuration')

    -- Door ID Input
    local doorIdInput = nil
    doorMenu.Add:Text('Door ID', { 'pad', 'textLarge', 'left' })
    doorMenu.Add:Input('Door Id (e.g. mrpd_entranceDoor_1)', {
        disabled = false,
        max = 255,
        current = doorIdInput,
    }, function(data)
        doorIdInput = data.data.value
        if Config.Debug then
            print("Door ID entered: " .. doorIdInput)
        end
    end)

    -- Double Door ID Input
    local doorDoubled = nil
    doorMenu.Add:Text('Double Door ID', { 'pad', 'textLarge', 'left' })
    doorMenu.Add:Input('ID of Second Door or Leave empty', {
        disabled = false,
        max = 255,
        current = doorDoubled,
    }, function(data)
        doorDoubled = data.data.value
        if Config.Debug then
            print("Second Door ID entered: " .. doorDoubled)
        end
    end)

    -- Locked Door Select Menu
    doorMenu.Add:Text('Is Door Locked?', { 'pad', 'textLarge', 'left' })
    local lockedStatus = doorConfig.locked
    doorMenu.Add:Select('Select', {
        disabled = false,
        current = lockedStatus and 1 or 2,
        list = {
            { label = 'Locked', value = 1 },
            { label = 'Unlocked', value = 2 },
        }
    }, function(data)
        lockedStatus = data.data.value == 1
        if Config.Debug then
            print("Door locked status selected: " .. (lockedStatus and "Locked" or "Unlocked"))
        end
    end)

    -- Adding Restriction
    local restrictionType = 'job'  -- Currently only 'job' is allowed
    local restrictionJob = ''
    local restrictionWorkplace = ''
    local restrictionGradeLevel = 0
    local restrictionJobPermission = false
    local restrictionReqDuty = false

    -- Dropdown to Select Auto Restriction
    local selectedAutoRestriction = nil
    local restrictionList = {}

    -- Populate the dropdown list from Config.AutoRestriction
    if Config.AutoRestriction then
        for key, restriction in pairs(Config.AutoRestriction) do
            table.insert(restrictionList, { label = key, value = key })
        end
    end

    doorMenu.Add:Text('Select Auto Restriction', { 'pad', 'textLarge', 'left' })

    doorMenu.Add:Select('Available Restrictions', {
        disabled = false,
        current = 1, -- Default to first item
        list = restrictionList
    }, function(data)
        selectedAutoRestriction = data.data.value
        if Config.Debug then
            print("Selected Auto Restriction: " .. selectedAutoRestriction)
        end
    end)

    -- Button to Apply Selected Auto Restriction
    doorMenu.Add:Button('Apply Selected Restriction', { success = true }, function()
        if selectedAutoRestriction and Config.AutoRestriction[selectedAutoRestriction] then
            local restriction = Config.AutoRestriction[selectedAutoRestriction]

            -- Check if the restriction already exists
            local exists = false
            for _, existing in ipairs(doorConfig.restricted) do
                if existing.job == restriction.id then
                    exists = true
                    break
                end
            end

            -- Add restriction if not already present
            if not exists then
                table.insert(doorConfig.restricted, {
                    type = 'job',
                    job = restriction.id,
                    workplace = restriction.workplace == false and 'false' or restrictionWorkplace,
                    gradeLevel = restriction.jobGrade,
                    jobPermission = false,
                    reqDuty = false,
                })

                Notification:Success('Restriction applied: ' .. selectedAutoRestriction, 3000, "check-circle")

                if Config.Debug then
                    print("Auto Restriction added: " .. selectedAutoRestriction)
                end
            else
                Notification:Error('Restriction already added!', 3000, "times-circle")
            end
        else
            Notification:Error('Please select a restriction!', 3000, "times-circle")
        end
    end)


    -- Add Restriction Fields
    doorMenu.Add:Text('Add Job Restriction', { 'pad', 'textLarge', 'left' })

    -- Type (job)
    doorMenu.Add:Select('Type', {
        disabled = false,
        current = restrictionType == 'job' and 1 or 0,
        list = {
            { label = 'Job', value = 1 },
            { label = 'RealHouse', value = 2 },
        }
    }, function(data)
        restrictionType = data.data.value == 1 and 'job' or ''
        restrictionType = data.data.value == 2 and 'RealHouse' or ''
        if Config.Debug then
            print("Type selected: " .. restrictionType)
        end
    end)

    -- Job Input
    doorMenu.Add:Input('Job Type (e.g. police) | HouseName (if its house)', {
        disabled = false,
        max = 255,
        current = restrictionJob,
    }, function(data)
        restrictionJob = data.data.value
        if Config.Debug then
            print("Job entered: " .. restrictionJob)
        end
    end)

    -- Workplace Input (Workplace Code or false)
    doorMenu.Add:Input('Workplace Access (eg. lspd or false)', {
        disabled = false,
        max = 255,
        current = restrictionWorkplace,
    }, function(data)
        -- If the input is empty, set it to false
        if data.data.value == '' then
            restrictionWorkplace = false  -- Explicitly set it to boolean false
        else
            -- Otherwise, use the workplace code entered
            restrictionWorkplace = data.data.value
        end
        if Config.Debug then
            -- Ensure the printout shows 'false' when workplace is empty
            print("Workplace Access: " .. (restrictionWorkplace == false and "false" or restrictionWorkplace))
        end
    end)

    -- Grade Level Input
    doorMenu.Add:Input('Grade Level', {
        disabled = false,
        max = 3,
        current = restrictionGradeLevel,
    }, function(data)
        restrictionGradeLevel = tonumber(data.data.value)
        if Config.Debug then
            print("Grade Level: " .. restrictionGradeLevel)
        end
    end)

    -- Job Permission (true/false selection)
    doorMenu.Add:Select('Job Permission (True/False)', {
        disabled = false,
        current = restrictionJobPermission and 1 or 2,
        list = {
            { label = 'True', value = 1 },
            { label = 'False', value = 2 },
        }
    }, function(data)
        restrictionJobPermission = data.data.value == 1
        if Config.Debug then
            print("Job Permission: " .. (restrictionJobPermission and "True" or "False"))
        end
    end)

    -- Require Duty (true/false selection)
    doorMenu.Add:Select('Require Duty (True/False)', {
        disabled = false,
        current = restrictionReqDuty and 1 or 2,
        list = {
            { label = 'True', value = 1 },
            { label = 'False', value = 2 },
        }
    }, function(data)
        restrictionReqDuty = data.data.value == 1
        if Config.Debug then
            print("Requires Duty: " .. (restrictionReqDuty and "True" or "False"))
        end
    end)

    -- Button to Add Restriction
    doorMenu.Add:Button('Add Restriction', { success = true }, function()
        -- Add the restriction to the doorConfig's restricted array
        if restrictionJob ~= '' and restrictionType == "job" then
            table.insert(doorConfig.restricted, {
                type = restrictionType,
                job = restrictionJob,
                workplace = restrictionWorkplace == false and 'false' or restrictionWorkplace,  -- Handle workplace as 'false' in string form
                gradeLevel = restrictionGradeLevel,
                jobPermission = restrictionJobPermission,
                reqDuty = restrictionReqDuty,
            })
            if Config.Debug then
                print("Restriction added: " .. restrictionJob)
            end
            local restrictionAddedNotify = tostring("You have added: " ..restrictionJob)
            Notification:Success(restrictionAddedNotify, 3500, "check-circle")
        elseif restrictionJob ~= '' and restrictionType == "RealHouse" then
            table.insert(doorConfig.restricted, {
                type = restrictionType,
                HouseName = restrictionJob,
            })
        else
            Notification:Error('Please enter a valid Job Type.', 3000, 'times-circle')
        end
    end)

    -- Save & Select Door
    doorMenu.Add:Button('Save & Select Door', { success = true }, function()
        -- Final Configuration
        doorConfig.id = doorIdInput
        doorConfig.locked = lockedStatus
        doorConfig.double = doorDoubled and doorDoubled or nil

        -- Print final door configuration to the console (optional)
        if Config.Debug then
            print("Final Door Configuration: ")
            print("Door ID: " .. doorConfig.id)
            print("Double Door ID: " .. (doorConfig.double or "None"))
            print("Locked: " .. (doorConfig.locked and "True" or "False"))
            print("Restrictions: ")
            for _, restriction in ipairs(doorConfig.restricted) do
                -- Explicitly check if the workplace is false
                local workplaceDisplay = (restriction.workplace == false or restriction.workplace == '' or restriction.workplace == nil) and 'false' or restriction.workplace
                local gradelevell = restriction.gradeLevel or 0
                print("Job: " .. (restriction.job or "None") .. ", Workplace: " .. workplaceDisplay .. ", Grade: " .. gradelevell)                
            end
        end


        Notification:Success('Look at the door and press E to save.', 4000, 'eye')
        WaitForDoorSelection(doorConfig)
        doorMenu:Close()
    end)

    doorMenu:Show()
end



-- Function to Save the Door Config
function SaveDoorConfig(door)
    -- Convert locked value to 'true' or 'false' before saving
    local lockedValue = door.locked and 'true' or 'false'
    local restrictionsFormatted = {}

    -- Format restrictions based on the data in door.restricted
    for _, restriction in ipairs(door.restricted) do
        if restriction.type == "job" then
            -- If workplace is false or empty, set it as 'false' (without quotes), otherwise treat it as a string
            local workplaceValue = (restriction.workplace == false or restriction.workplace == '') and 'false' or "'" .. restriction.workplace .. "'"
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

    -- Format the door data into the save string
    local newDoorData = string.format([[ 
        {
            id = "%s",
            model = %s,
            coords = vector3(%s, %s, %s),
            locked = %s,
            double = %s,
            rate = 6.0,
            restricted = { %s }
        },
    ]], door.id, door.model, door.coords.x, door.coords.y, door.coords.z, lockedValue, door.double and '"' .. door.double .. '"' or 'nil', table.concat(restrictionsFormatted, ", "))

    -- Send data to the server for saving
    TriggerServerEvent('cs-doorLock:saveConfig', newDoorData)

    Notification:Success('Door configuration saved!', 3500, 'check-circle')
end

-- Command to Open the Menu
RegisterNetEvent('cs-doorLock:openMenu')
AddEventHandler('cs-doorLock:openMenu', function()
    OpenDoorConfigMenu()
end)