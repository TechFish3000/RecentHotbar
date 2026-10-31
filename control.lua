function scroll(event)
    --log("Scroll Called")

    -- this is the main function that handles the scrolling
    --when the player selects an item

    --get the player that this event has been called for
    local player = game.players[event.player_index]

    -- if this player doesn't want the mod then don't process any further
    if not settings.get_player_settings(player)["enable-mod"].value then
        return
    end

    -- get whether to add items that aren't placeable
    local do_items = settings.get_player_settings(player)["do-items-in-hotbar"].value

    -- get which hotbar to work in and use it to index
    local working_hotbar = settings.get_player_settings(player)["working-hotbar"].value
    if (working_hotbar == 0) then
        working_hotbar = 10; -- more accurately reflect the hotbar numbering ingame
    end

    -- get whether to sort right-left instead
    local right_left = settings.get_player_settings(player)["sort-rl"].value

    -- if not sorting right-left
    local left_right = not right_left

    -- whether this was a pipette that brings a ghost item to the cursor or just a regular item
    local useGhost = event.item ~= nil

    -- whether the mod setting to add ghosts is enabled
    local shouldAddGhosts = settings.get_player_settings(player)["do-ghosts-in-hotbar"].value

    -- whether we should be sorting in place instead of scrolling
    local sortInPlace = settings.get_player_settings(player)["sort-inplace"].value

    -- if this was a ghost pipette but the user doesn't want ghosts added then return
    if useGhost and not shouldAddGhosts then
        return
    end

    -- if an item pipette but cursor isn't valid
    if not useGhost and not player.cursor_stack.valid_for_read then
        return
    end


    -- if its an item pipette, and there's no place result while we aren't doing non-placeables also
    if (not useGhost) and player.cursor_stack.prototype.place_result == nil and (not do_items) then
        return
    end

    -- if we pipette a non-placeable item ghost when we aren't adding non-placeables
    if useGhost and player.cursor_ghost.name.place_result == nil and (not do_items) then
        return
    end

    -- if the ghost pipette is somehow invalid (probably shouldn't happen but just in case)
    if useGhost and player.cursor_ghost == nil then
        return
    end

    -- if its a temporary item like an unfilled blueprint or decon planner, skip
    if player.cursor_stack_temporary then
        return
    end

    -- make sure cursor is valid for reading
    if (player.cursor_stack.valid_for_read) then
        -- empty spidertron remotes cant be added to quickbar at all so skip them
        if (player.cursor_stack.type == "spidertron-remote" and (player.spidertron_remote_selection == nil or #(player.spidertron_remote_selection) == 0)) then
            return
        end
    end

    local useFullQuickbar = settings.get_player_settings(player)["full-quickbar"].value
    local QBWidth = 10
    if (useFullQuickbar) then
        QBWidth = player.quick_bar_width
    end

    --log(player.cursor_stack.name) -- log the name for debugging
    --log(player.cursor_stack.count) -- log the count

    local startIndex = 1
    local endIndex = 1
    local direction = 1

    -- figure out search directions
    if left_right then
        startIndex = 1
        endIndex = QBWidth
        direction = 1
    elseif right_left then
        startIndex = QBWidth
        endIndex = 1
        direction = -1
    end

    local selected = nil

    -- find first empty slot or slot with the exact same item we are pipetting
    for num = startIndex, endIndex, direction do
        local slot = player.get_quick_bar_slot(working_hotbar, num) -- just in case it doesnt cache, take slightly less time

        -- found out why it broke so bad, turns out get_quick_bar_slot returns a slot now that contains a filter, instead of the filter itself

        if (slot ~= nil) then -- no longer selects an empty slot if the item is already present
            -- new slot types are a bit of a pain but do make a lot more sense ngl

            if (slot.type == "remote") then -- if its a spidertron remote
                if (slot.selection and player.cursor_stack.valid_for_read and player.cursor_stack.type == "spidertron-remote") then
                    -- compare if the two remotes refer to the same spiders, if so then its probably the same remote
                    local selectionA = slot.selection
                    local selectionB = player.spidertron_remote_selection
                    local same = true
                    local spiders = {}

                    if (#selectionA == #selectionB) then
                        -- build seen list
                        for _, spider in ipairs(selectionA) do
                            spiders[spider.unit_number] = true
                        end

                        -- compare seen list
                        for _, spider in ipairs(selectionB) do
                            if not spiders[spider.unit_number] then
                                same = false
                                break
                            end
                        end
                    else
                        same = false
                    end
                    if (same) then
                        selected = num
                        break
                    end
                end
            elseif (slot.type == "item") then -- if its a unique item (artillery designator or inventory blueprint)
                if (slot.item.valid and player.cursor_stack.valid_for_read) then
                    -- compare their item_number which is basically a unique ID
                    if (slot.item.item_number ~= nil and slot.item.item_number == player.cursor_stack.item_number) then
                        selected = num
                        break
                    end
                end
            elseif (slot.type == "filter") then -- if its an item filter
                local slotFilter = slot.filter

                -- if (slot ~= nil) then
                --     player.print(slot)
                --     player.print(slot.filter)
                -- end

                -- if this filter is empty somehow
                if (slotFilter == nil) then
                    selected = num
                    break
                end


                -- whether its a ghost or not
                if (not useGhost) then
                    -- if the cursor stack matches the slot stack item and quality
                    player.print("not ghost")
                    if (player.cursor_stack.name == slotFilter.name and player.cursor_stack.quality.name == slotFilter.quality) then
                        selected = num
                        break
                    end
                else
                    -- if the cursor ghost matches the slot stack item and quality
                    player.print("ghost")
                    if (player.cursor_ghost.name.name == slotFilter.name and player.cursor_ghost.quality.name == slotFilter.quality) then
                        selected = num
                        break
                    end
                end
            end -- dont care about records, not sure how to implement them properly, maybe one day

            -- old
            -- if not useGhost then
            --     if (slotFilter == nil or (player.cursor_stack.name == slotFilter.name and player.cursor_stack.quality.name == slotFilter.quality)) and selected == nil then
            --         selected = num
            --     end
            -- else
            --     if (slotFilter == nil or (player.cursor_ghost.name.name == slotFilter.name and player.cursor_ghost.quality.name == slotFilter.quality)) and selected == nil then
            --         selected = num
            --     end
            -- end
        end
    end

    -- if no items were already present then find the first empty slot instead
    if (selected == nil) then
        for num = startIndex, endIndex, direction do
            local slot = player.get_quick_bar_slot(working_hotbar, num)
            if (slot == nil) then
                selected = num
                break
            end
        end
    end

    -- if (selected == nil) then
    --     player.print("Selected: nil")
    -- else
    --     player.print("Selected:" .. selected)
    -- end

    -- really wish lua had pythons ternary
    -- couldve just been player.print("Selected:" .. "nil" if selected == nil else selected)
    -- or even c's ternary
    -- player.print("Selected: " .. selected == nil ? "nil" : selected)
    -- one can dream of lua making sense

    -- then fill slots

    if (not sortInPlace) then
        -- if there was no holes to fill then start from the given end
        if selected == nil and left_right then
            selected = QBWidth
        elseif selected == nil and right_left then
            selected = 1
        end

        -- figure out which direction to go
        if left_right then
            startIndex = selected
            endIndex = 2
            direction = -1
        elseif right_left then
            startIndex = selected
            endIndex = QBWidth - 1
            direction = 1
        end

        -- shuffle stuff over
        for num = startIndex, endIndex, direction do
            player.set_quick_bar_slot(working_hotbar, num, player.get_quick_bar_slot(working_hotbar, (num + direction)))
        end

        -- then set the first/last item to the new one
        if left_right then
            if not useGhost then
                player.set_quick_bar_slot(working_hotbar, 1, player.cursor_stack)
            else
                player.set_quick_bar_slot(working_hotbar, 1, { type = "filter", filter = player.cursor_ghost })
            end
        elseif right_left then
            if not useGhost then
                player.set_quick_bar_slot(working_hotbar, QBWidth, player.cursor_stack)
            else
                player.set_quick_bar_slot(working_hotbar, QBWidth, { type = "filter", filter = player.cursor_ghost })
            end
        end
    else
        --game.players[event.player_index].print("a")
        -- if sorting in place
        if (selected == nil) then
            -- find which of the toolbar slots is the oldest

            -- setup table if not existing
            if (storage.playerToolbarTimes[event.player_index] == nil) then
                for num = 1, QBWidth do
                    storage.playerToolbarTimes[event.player_index][num] = game.ticks_played
                end
            end

            local oldestIndex = 1
            local lowestTick = storage.playerToolbarTimes[event.player_index][1]
            for num = 1, QBWidth do
                --game.players[event.player_index].print("b")
                --game.players[event.player_index].print(storage.playerToolbarTimes[event.player_index][num])
                if (storage.playerToolbarTimes[event.player_index][num] == nil) then        -- if the spot isnt existing, after having extended the bar manually
                    storage.playerToolbarTimes[event.player_index][num] = game.ticks_played -- ensure it is existing
                end
                if (storage.playerToolbarTimes[event.player_index][num] < lowestTick) then
                    lowestTick = storage.playerToolbarTimes[event.player_index][num]
                    oldestIndex = num
                end
            end
            selected = oldestIndex
            -- we now have the oldest slot index
        end

        local slotToFill = selected

        if not useGhost then
            player.set_quick_bar_slot(working_hotbar, slotToFill, player.cursor_stack)
        else
            player.set_quick_bar_slot(working_hotbar, slotToFill, { type = "filter", filter = player.cursor_ghost })
        end
        storage.playerToolbarTimes[event.player_index][selected] = game.ticks_played
    end
end

-- table of what every player had in their ghost cursor last frame
lastCursors = {}

-- function to check for new things in each player's ghost cursor since it doesn't appear to fire an event when selecting a ghost from the hotbar
function cursorCheck()
    for idx, player in pairs(game.players) do
        if (player.cursor_ghost ~= nil) then
            if (player.cursor_ghost.name ~= lastCursors[idx]) then
                -- effectively just call the scroll function as if an event was fired
                scroll({ player_index = idx, item = player.cursor_ghost })
                --player.print("scrolled")
                --if (lastCursors[idx] ~= nil) then
                --    player.print(lastCursors[idx])
                --end
                --player.print(player.cursor_ghost.name)
            end
        end
        if player.cursor_ghost ~= nil then
            lastCursors[idx] = player.cursor_ghost.name
        else
            lastCursors[idx] = nil
        end
    end
end

function recheckQuickbars(event)
    if (not settings.get_player_settings(event.player_index)["sort-inplace"].value) then
        return
    end
end

script.on_event(defines.events.on_player_cursor_stack_changed, scroll)
script.on_event(defines.events.on_tick, cursorCheck)

--script.on_event(defines.events.on_player_pipette, scroll)
-- I realised that with the new cursorCheck function that the logic would run twice if i also made it run for pipette which was a fix for the hotbar, so it's commented out

script.on_event(defines.events.on_player_set_quick_bar_slot, recheckQuickbars)

script.on_init(function()
    storage.playerToolbarTimes = {}

    for idx, player in pairs(game.players) do
        local useFullQuickbar = settings.get_player_settings(player)["full-quickbar"].value
        local QBWidth = 10
        if (useFullQuickbar) then
            QBWidth = player.quick_bar_width
        end
        storage.playerToolbarTimes[idx] = {}
        for num = 1, QBWidth do
            storage.playerToolbarTimes[idx][num] = game.ticks_played
        end
    end
end)

script.on_event(defines.events.on_player_joined_game, function(ev)
    if (storage.playerToolbarTimes == nil) then
        storage.playerToolbarTimes = {}
    end
    if (storage.playerToolbarTimes[ev.player_index] == nil) then
        storage.playerToolbarTimes[ev.player_index] = {}
        local useFullQuickbar = settings.get_player_settings(player)["full-quickbar"].value
        local QBWidth = 10
        if (useFullQuickbar) then
            QBWidth = player.quick_bar_width
        end
        for num = 1, QBWidth do
            storage.playerToolbarTimes[ev.player_index][num] = game.ticks_played
        end
    end
end)
