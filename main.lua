-- mod.lua

-- Register the mod
local mod = RegisterMod("Fast Restart", 1)

-- Initialize variables
local planetariumFound = false
local libraryFound = false
local treasureRoom = -1
local OnlyOnce = false
local OnlyOnceT = false
local frameCount = 0

-- Function to check floor contents
function CheckFloorContents()
    -- Reset variables
    planetariumFound = false
    libraryFound = false
    OnlyOnce = false
    OnlyOnceT = false
    frameCount = 0
    treasureRoom = -1
    
    -- Get the current level and room list
    local level = Game():GetLevel()
    local Roomlist = level:GetRooms()

    -- Iterate through all rooms on the current floor
    for i = 0, Roomlist.Size - 2, 1 do
        local roomDesc = Roomlist:Get(i)
        local room = roomDesc.Data.Type

        -- Check if the room is a planetarium
        if room == RoomType.ROOM_PLANETARIUM then
            planetariumFound = true
        -- Check if the room is a library
        elseif room == RoomType.ROOM_LIBRARY then
            libraryFound = true
        end
    end
end

-- Function to print room contents
function PrintRooms()
    -- Get the current level and stage
    local level = Game():GetLevel()
    local stage = level:GetStage()

    -- Check if it's the first stage of the first floor
    if stage == LevelStage.STAGE1_1 then
        -- Teleport to the treasure room only once
        if not OnlyOnce then
            Isaac.ExecuteCommand("goto s.treasure")
            OnlyOnce = true
        end
    end

    -- Get the current room
    local roomT = Game():GetRoom()

    -- Check if the current room is a treasure room and it's the first time
    if roomT:GetType() == RoomType.ROOM_TREASURE and not OnlyOnceT then
        -- Get the item quality
        local roomEntities = Isaac.GetRoomEntities()
        for i, entity in ipairs(roomEntities) do
            if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                local item = Isaac.GetItemConfig():GetCollectible(entity.SubType)
                treasureRoom = item.Quality
            end
        end

        -- Use the glowing hourglass active item
        local player = Isaac.GetPlayer(0)
        player:UseActiveItem(422)

        -- Print the item quality
        Isaac.RenderText(tostring(treasureRoom), 100, 140, 1, 1, 1, 255)
        Isaac.ConsoleOutput(tostring(frameCount))
        OnlyOnceT = true
    end

    -- Check if the conditions are met for restarting the game
    if (planetariumFound == false and libraryFound == false and treasureRoom < 3 and frameCount > 30) then
        if Epiphany then
            Epiphany.runRestartedWithRInstant = true
        end
        Isaac.ExecuteCommand("restart")
        OnlyOnce = false
        return false
    -- Print the floor contents if the conditions are not met
    elseif planetariumFound == false or libraryFound == false or treasureRoom < 3 then
        if libraryFound then
            Isaac.RenderText("Library found on this floor!", 100, 100, 255, 255, 255, 255)
        end
        if planetariumFound then
            Isaac.RenderText("Planetarium found on this floor!", 100, 150, 255, 255, 255, 255)
        end
        if treasureRoom >= 3 then
            Isaac.RenderText("Item is tier 3 or higher", 100, 200, 255, 255, 255, 255)
        end
    end
end

-- Function to count frames
function CountFrames()
    frameCount = frameCount + 1
end

-- Function to handle restart input
local function inputAction(_, _, _, buttonAction)
    if Input.IsActionTriggered(ButtonAction.ACTION_RESTART, 0)
        and buttonAction == ButtonAction.ACTION_RESTART
        and not Game():IsPaused()
        and Game():GetLevel():GetStage() == LevelStage.STAGE1_1
        and not Game():GetLevel():IsAscent() then
        Isaac.DebugString("----- instant-restart - Restart -----  ")

        if Epiphany then
            Epiphany.runRestartedWithRInstant = true
        end

        Isaac.ExecuteCommand("restart")
        return false
    end
end

-- Register callbacks
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, CountFrames)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, CheckFloorContents)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, PrintRooms)
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, inputAction, InputHook.IS_ACTION_PRESSED)
