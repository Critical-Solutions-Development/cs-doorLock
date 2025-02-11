

AddEventHandler('cs-doorLock', RetrieveComponents)
function RetrieveComponents()
    Chat = exports['mythic-base']:FetchComponent('Chat')
end

AddEventHandler('Core:Shared:Ready', function()
    exports['mythic-base']:RequestDependencies('Doors', {
        'Chat',
    }, function(error)
        if #error > 0 then return end
        RetrieveComponents()

        Chat:RegisterCommand("doorLock", function(source)
            TriggerClientEvent('cs-doorLock:openMenu', source)
        end, {
            help = "Admin command to make new doors",
            params = {}
        }, 0)
    end)
end)

RegisterNetEvent('cs-doorLock:saveConfig')
AddEventHandler('cs-doorLock:saveConfig', function(newDoorData)
    local fileName = 'door_config.txt'

    -- Load existing door data
    local existingData = LoadResourceFile(GetCurrentResourceName(), fileName)

    if not existingData or existingData == "" then
        -- If the file is empty, start fresh
        print('[cs-doorLock] File is empty, creating new door configuration.')
        existingData = "addDoorsListToConfig({\n" .. newDoorData .. "\n})"
    else
        -- Debugging the current contents of the file
        print('[cs-doorLock] Existing Data: ' .. existingData)

        -- Check if the file already has the closing parenthesis (}) at the end
        if existingData:sub(-2) == "})" then
            -- Remove the last closing parenthesis and add the new door data before it
            existingData = existingData:sub(1, -3)  -- Remove "})"
            existingData = existingData .. "\n" .. newDoorData .. "\n})"
        else
            -- Something went wrong with the formatting, so we start fresh
            print('[cs-doorLock] Error: File format is incorrect. Starting fresh.')
            existingData = "addDoorsListToConfig({\n    " .. newDoorData .. "\n})"
        end
    end

    -- Save the updated door list back to the file
    local result = SaveResourceFile(GetCurrentResourceName(), fileName, existingData, -1)
    
    -- Debugging if saving is successful
    if result then
        print('[cs-doorLock] New door configuration saved successfully!')
    else
        print('[cs-doorLock] Error saving door configuration!')
    end
end)
