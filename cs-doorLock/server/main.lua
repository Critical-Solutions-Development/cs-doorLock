

AddEventHandler("cs-doorLock", RetrieveComponents)
function RetrieveComponents()
    Logger = exports["mythic-base"]:FetchComponent("Logger")
    Chat = exports["mythic-base"]:FetchComponent("Chat")
    Fetch = exports["mythic-base"]:FetchComponent('Fetch')
end

AddEventHandler('Core:Shared:Ready', function()
    exports["mythic-base"]:RequestDependencies("Doors", {
        "Logger",
        "Chat",
        "Fetch"
    }, function(error)
        if #error > 0 then return end
        RetrieveComponents()

        Chat:RegisterAdminCommand("doorLock", function(source)
            TriggerClientEvent('cs-doorLock:openMenu', source)
        end, {
            help = "Admin command to make new doors",
            params = {}
        }, 0)
    end)
end)

RegisterNetEvent('cs-doorLock:saveConfig')
AddEventHandler('cs-doorLock:saveConfig', function(newDoorData)
    local lvl = Fetch:Source(source).Permissions:GetLevel()
    if lvl >= 75 then 
        local fileName = 'door_config.txt'

        -- Load existing door data
        local existingData = LoadResourceFile(GetCurrentResourceName(), fileName)

        if not existingData or existingData == "" then
            -- If the file is empty, start fresh
            Logger:Info("cs-doorLock", "New file created")
            existingData = "addDoorsListToConfig({\n" .. newDoorData .. "\n})"
        else
            -- Check if the file already has the closing parenthesis (}) at the end
            if existingData:sub(-2) == "})" then
                -- Remove the last closing parenthesis and add the new door data before it
                existingData = existingData:sub(1, -3)  -- Remove "})"
                existingData = existingData .. "\n" .. newDoorData .. "\n})"
            else
                -- Something went wrong with the formatting, so we start fresh
                Logger:Error("cs-doorLock", "File Format incorrect.")
                existingData = "addDoorsListToConfig({\n    " .. newDoorData .. "\n})"
            end
        end

        -- Save the updated door list back to the file
        local result = SaveResourceFile(GetCurrentResourceName(), fileName, existingData, -1)
            
        -- Debugging if saving is successful
        if result then
            Logger:Info("cs-doorLock", "New Door Saved to the File")
        else
            Logger:Error("cs-doorLock", "Error Saving Door Configuration.")
        end
    else 
        return
    end
end)

RegisterNetEvent('cs-doorLock:saveGaragePoly')
AddEventHandler('cs-doorLock:saveGaragePoly', function(newGarageData)
    local lvl = Fetch:Source(source).Permissions:GetLevel()
    if lvl >= 75 then 
        local fileName = 'garage_polys.lua'

        -- Load existing data from file
        local existingData = LoadResourceFile(GetCurrentResourceName(), fileName) or ""

        -- Trim any leading/trailing whitespace
        existingData = existingData:match("^%s*(.-)%s*$")

        if not existingData or existingData == "" then
            -- Start fresh if the file is empty
            Logger:Info("cs-doorLock", "Garage file created")
            existingData = newGarageData
        else
            -- Append new garage zone data before final closing `})`
            if existingData:sub(-2) == "})" then
                existingData = existingData:sub(1, -3) -- Remove "})"
                existingData = existingData .. "\n" .. newGarageData .. "\n})"
            else
                -- Fallback if formatting is broken
                Logger:Error("cs-doorLock", "Garage File format incorrect.")
                existingData = newGarageData
            end
        end

        -- Save updated data back to the file
        local result = SaveResourceFile(GetCurrentResourceName(), fileName, existingData, -1)

        if result then
            Logger:Info("cs-doorLock", "Garage zone saved successfully.")
        else
            Logger:Error("cs-doorLock", "Error saving garage polyzone.")
        end
    else
        Logger:Error("cs-doorLock", "Insufficient permissions to save garage polyzone.")
    end
end)

