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

    -- Special Door Select Menu
    doorMenu.Add:Text('Is Door Special?', { 'pad', 'textLarge', 'left' })
    local specialStatus = doorConfig.special or false
    doorMenu.Add:Select('Select', {
        disabled = false,
        current = specialStatus and 2 or 1, -- fix for default
        list = {
            { label = 'Not Special', value = 1 },
            { label = 'Special', value = 2 },
        }
    }, function(data)
        specialStatus = data.data.value == 2
        if Config.Debug then
            print("Door special status selected: " .. (specialStatus and "Special" or "Not Special"))
        end
    end)


    -- Adding Restriction
    local restrictionType = 'job'  
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
    doorMenu.Add:Text('Set Custom Restrictions', { 'pad', 'textLarge', 'left' })

    local _subJobMenu = Menu:Create('subJobMenu', 'Job Restrictions')
    ShowJobRestrictions(_subJobMenu, doorConfig)
    _subJobMenu.Add:SubMenuBack('Back')

    local _subHouseMenu = Menu:Create('subHouseMenu', 'House Restrictions')
    ShowHouseRestrictions(_subHouseMenu, doorConfig)
    _subHouseMenu.Add:SubMenuBack('Back')

    local _subGarageMenu = Menu:Create('subGarageMenu', 'Garage')
    GarageMenu(_subGarageMenu, doorConfig)
    _subGarageMenu.Add:SubMenuBack('Back')

    doorMenu.Add:SubMenu('Restrict to Job', _subJobMenu)
    doorMenu.Add:SubMenu('Restrict to House', _subHouseMenu)
    doorMenu.Add:SubMenu('Make it a Garage', _subGarageMenu)

    -- Save & Select Door
    doorMenu.Add:Button('Save & Select Door', { success = true }, function()
        -- Final Configuration
        doorConfig.id = doorIdInput
        doorConfig.locked = lockedStatus
        doorConfig.double = doorDoubled and doorDoubled or nil
        doorConfig.special = specialStatus -- ✅ Include special status!

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

function ShowHouseRestrictions(_Menu, _DoorConfig)
    local doorMenu = _Menu
    local doorConfig = _DoorConfig

    -- Job Input
    doorMenu.Add:Input('HouseName', {
        disabled = false,
        max = 255,
        current = restrictionJob,
    }, function(data)
        restrictionJob = data.data.value
        if Config.Debug then
            print("Job entered: " .. restrictionJob)
        end
   
    end)

    -- Button to Add Restriction
    doorMenu.Add:Button('Add Restriction', { success = true }, function()
        -- Add the restriction to the doorConfig's restricted array
        table.insert(doorConfig.restricted, {
            type = 'RealHouse',
            HouseName = restrictionJob,})
        if Config.Debug then
            print("Restriction added: " .. restrictionJob)
        end
        local restrictionAddedNotify = tostring("You have added: " ..restrictionJob)
        Notification:Success(restrictionAddedNotify, 3500, "check-circle")
    end)
end

function ShowJobRestrictions(_Menu, _DoorConfig)
    
    local doorMenu = _Menu
    local doorConfig = _DoorConfig
    

    -- Job Input
    doorMenu.Add:Input('Job Type (e.g. police)', {
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
        table.insert(doorConfig.restricted, {
            type = 'job',
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
    end)
end

function GarageMenu(_Menu, _DoorConfig)
    local doorMenu = _Menu
    local doorConfig = _DoorConfig

    local zoneName, zoneX, zoneY, zoneZ = nil, nil, nil, nil
    local length, width, heading = 4.0, 4.0, 0.0
    local minZ, maxZ = 0.0, 3.0
    local doorGarageId = nil  -- New variable for door garage ID

    doorMenu.Add:Text('Set Garage PolyZone', { 'pad', 'textLarge', 'left' })

    -- Zone Name
    doorMenu.Add:Input('Zone Name', {
        disabled = false,
        max = 255,
        current = zoneName or '',
    }, function(data)
        zoneName = data.data.value
    end)

    -- Coords
    doorMenu.Add:Input('Zone Center X', { disabled = false, max = 10, current = '' }, function(data)
        zoneX = tonumber(data.data.value)
    end)
    doorMenu.Add:Input('Zone Center Y', { disabled = false, max = 10, current = '' }, function(data)
        zoneY = tonumber(data.data.value)
    end)
    doorMenu.Add:Input('Zone Center Z', { disabled = false, max = 10, current = '' }, function(data)
        zoneZ = tonumber(data.data.value)
    end)

    -- Dimensions
    doorMenu.Add:Input('Length', { disabled = false, max = 10, current = tostring(length) }, function(data)
        length = tonumber(data.data.value) or length
    end)
    doorMenu.Add:Input('Width', { disabled = false, max = 10, current = tostring(width) }, function(data)
        width = tonumber(data.data.value) or width
    end)

    -- Heading
    doorMenu.Add:Input('Heading', { disabled = false, max = 10, current = tostring(heading) }, function(data)
        heading = tonumber(data.data.value) or heading
    end)

    -- Z bounds
    doorMenu.Add:Input('Min Z', { disabled = false, max = 10, current = tostring(minZ) }, function(data)
        minZ = tonumber(data.data.value) or minZ
    end)
    doorMenu.Add:Input('Max Z', { disabled = false, max = 10, current = tostring(maxZ) }, function(data)
        maxZ = tonumber(data.data.value) or maxZ
    end)

    -- Door Garage ID
    doorMenu.Add:Input('Garage Door ID', {
        disabled = false,
        max = 255,
        current = doorGarageId or '',
    }, function(data)
        doorGarageId = data.data.value
    end)

    -- Final Save Button
    doorMenu.Add:Button('Save Garage Zone', {}, function()
        if not zoneName or not zoneX or not zoneY or not zoneZ or not doorGarageId then
            Notification:Error('Missing required zone data.', 3000, 'alert-triangle')
            return
        end

        local zoneString = string.format([[
function CreateGaragePolyZones()
    Polyzone.Create:Box('%s', vector3(%s, %s, %s), %s, %s, {
        heading = %s,
        minZ = %s,
        maxZ = %s
    }, {
        door_garage_id = '%s'
    })
end
]], zoneName, zoneX, zoneY, zoneZ, length, width, heading, minZ, maxZ, doorGarageId)

        -- Send to server to save as file
        TriggerServerEvent('cs-doorLock:saveGaragePoly', zoneString)
        Notification:Success('Garage polyzone config saved!', 3500, 'check-circle')
    end)
end
