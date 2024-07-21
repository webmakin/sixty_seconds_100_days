    -- This section prevents the camera from viewing outside the background
    -- First, get width/height of the game window
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- Left border
    if cam.x < w/2 then
        cam.x = w/2
    end

    -- Right border
    if cam.y < h/2 then
        cam.y = h/2
    end

    -- Get width/height of background
    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    -- Right border
    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end
    -- Bottom border
    if cam.y > (mapH - h/2) then
        cam.y = (mapH - h/2)
    end


    ,
                    {
                        "name": "barrel",
                        "img": "objects_06.png",
                        "hp": 50    
                    }

                        --contents = love.filesystem.load('libraries/real_collectibles.json')
    -- print(contents)
    -- if contents then
    --     real_collectibles = json.decode(contents)
    -- end

        -- kep the player in the map
    -- player.x = math.max(0, math.min(windowWidth - 150, player.x))
    -- player.y = math.max(0, math.min(windowHeight - 150, player.y))

            -- local colliders = world:queryCircleArea(player.x, player.y, 100, {'Collectibles'})
        -- if #colliders > 0 then
        --     for i,c in ipairs(colliders) do      
        --         table.remove(collectibles, i) 
        --         --c:destroy()
        --     end
        -- end