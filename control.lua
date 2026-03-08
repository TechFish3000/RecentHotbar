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
    local hotbar_offset = (settings.get_player_settings(player)["working-hotbar"].value * 10) - 10

    -- get whether to sort right-left instead
    local right_left = settings.get_player_settings(player)["sort-rl"].value

    -- if not sorting right-left
    local left_right = not right_left

    -- whether this was a pipette that brings a ghost item to the cursor or just a regular item
    local useGhost = event.item ~= nil

    -- whether the mod setting to add ghosts is enabled
    local shouldAddGhosts = settings.get_player_settings(player)["do-ghosts-in-hotbar"].value



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

    --log(player.cursor_stack.name) -- log the name for debugging
    --log(player.cursor_stack.count) -- log the count

    local startIndex = 1
    local endIndex = 1
    local direction = 1

    if left_right then
        startIndex = 1
        endIndex = 10
        direction = 1

    elseif right_left then
        startIndex = 10
        endIndex = 1
        direction = -1

    end

    local selected = nil

    for num = startIndex, endIndex, direction do

        if not useGhost then
            if (player.get_quick_bar_slot(num + hotbar_offset) == nil or (player.cursor_stack.name == player.get_quick_bar_slot(num + hotbar_offset).name and player.cursor_stack.quality.name == player.get_quick_bar_slot(num + hotbar_offset).quality)) and selected == nil then
                selected = num
            end
        else
            if (player.get_quick_bar_slot(num + hotbar_offset) == nil or (player.cursor_ghost.name.name == player.get_quick_bar_slot(num + hotbar_offset).name and player.cursor_ghost.quality.name == player.get_quick_bar_slot(num + hotbar_offset).quality)) and selected == nil then
                selected = num
            end
        end
    end

    -- if there was no holes to fill then start from the given end
    if selected == nil and left_right then
        selected = 10
    elseif selected == nil and right_left then
        selected = 1
    end

    if left_right then
        startIndex = selected
        endIndex = 2
        direction = -1
    elseif right_left then
        startIndex = selected
        endIndex = 9
        direction = 1
    end

    for num = startIndex, endIndex, direction do
        player.set_quick_bar_slot(num + hotbar_offset, player.get_quick_bar_slot((num + direction) + hotbar_offset))
    end

    if left_right then
        if not useGhost then
            player.set_quick_bar_slot(1 + hotbar_offset, player.cursor_stack)
        else
            player.set_quick_bar_slot(1 + hotbar_offset, player.cursor_ghost)
        end
    elseif right_left then
        if not useGhost then
            player.set_quick_bar_slot(10 + hotbar_offset, player.cursor_stack)
        else
            player.set_quick_bar_slot(10 + hotbar_offset, player.cursor_ghost)
        end
    end

end

-- table of what every player had in their ghost cursor last frame
lastCursors = {}

-- function to check for new things in each player's ghost cursor since it doesn't appear to fire an event when selecting a ghost from the hotbar
function cursorCheck()
    for idx, player in pairs(game.players) do
        if (player.cursor_ghost ~= lastCursors[idx] and player.cursor_ghost ~= nil) then
            -- effectively just call the scroll function as if an event was fired
            scroll({ player_index = idx, item = player.cursor_ghost })
        end
        lastCursors[idx] = player.cursor_ghost
    end

end

script.on_event(defines.events.on_player_cursor_stack_changed, scroll)
script.on_event(defines.events.on_tick, cursorCheck)

--script.on_event(defines.events.on_player_pipette, scroll)
-- I realised that with the new cursorCheck function that the logic would run twice if i also made it run for pipette which was a fix for the hotbar, so it's commented out 
