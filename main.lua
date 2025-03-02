--------------------------------------------------------------------------------
-- Quake variables (initialized to avoid nil comparisons)
--------------------------------------------------------------------------------
local quakeDuration = 5.0  -- how many seconds the quake effect lasts
local quakeTimer    = 0    -- current time left of shaking
local quakeOffsetX  = 0
local quakeOffsetY  = 0

--------------------------------------------------------------------------------
function love.load()
    --json = require 'libraries/json'
    json = require 'libraries/dkjson'
    wf = require 'libraries/windfield'
    world = wf.newWorld(0,0)

    world:addCollisionClass('Player'--[[, {ignores = {'Doors'}}]])
    world:addCollisionClass('Walls')
    world:addCollisionClass('Doors')
    world:addCollisionClass('Collectibles')

    camera = require 'libraries/camera'
    cam = camera()
    gameState = 1  --1 is main menu, 2 is game in session
    timer = 60     -- Initialize timer to 60 seconds
    currentLevel = 1
    quakeTimer = 0 -- Make sure quakeTimer starts at 0
    
    timerFont = love.graphics.newFont(25)
    
    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")
    sti = require 'libraries/sti'
    
    --levels = {}

    player = {}
    playerStartX = 400
    playerStartY = 200
    player.collider = world:newBSGRectangleCollider(400, 250, 50, 100, 10, {collision_class = "Player"})
    player.collider:setFixedRotation(true)
    player.x = playerStartX
    player.y = playerStartY
    player.speed = 300
    player.spriteSheet1 = love.graphics.newImage('sprites/parrot.png')
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid( 12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
    
    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid('1-4', 1), 0.2)
    player.animations.left = anim8.newAnimation( player.grid('1-4', 2), 0.2)
    player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2)
    player.animations.up = anim8.newAnimation( player.grid('1-4', 4), 0.2)
    player.anim = player.animations.left

    walls = {}
    doors = {}
    collectibles = {}
    loadMap(currentLevel)
   
    inventory = {}
    maxInventorySlots = 9
end

--------------------------------------------------------------------------------
function spawnWalls()
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height, {collision_class = "Walls"})
            wall:setType('static')
            table.insert(walls, wall)
        end
    end
end

--------------------------------------------------------------------------------
function spawnDoors()
    if gameMap.layers["doors"] then
        for i, obj in pairs(gameMap.layers["doors"].objects) do
            local door = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height, {collision_class = "Doors"})
            door:setType('static')
            table.insert(doors, door)
        end
    end
end

--------------------------------------------------------------------------------
function spawnCollectibles()
     -- get the collectibles json
     local collectibles_file = love.filesystem.read('loaders/collectibles'.. currentLevel ..'.json')
     real_collectibles = json.decode(collectibles_file)

     if gameMap.layers["collectibles"] then
         for i, obj in pairs(gameMap.layers["collectibles"].objects) do
             local collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height, {collision_class = "Collectibles"})
             collider:setType('static')
             local collectible = {}
             collectible.collider = collider
             collectible.x = obj.x
             collectible.y = obj.y
             if real_collectibles[i] then
                 local img_sheet = love.graphics.newImage('maps/collectibles'.. currentLevel ..'/'..real_collectibles[i].img)
                 collectible.img = img_sheet
             else
                 collectible.img = player.spriteSheet1
             end
             table.insert(collectibles, collectible)
         end
     end
end


function destroyAll()
    --remove walls
    local i = #walls
    while i > -1 do
        if walls[i] and walls[i] ~= nil then
            walls[i]:destroy()
        end
        table.remove(walls, i)
        i = i -1
    end

    --remove doors
    local i = #doors
    while i > -1 do
        if doors[i] and doors[i] ~= nil then
            doors[i]:destroy()
        end
        table.remove(doors, i)
        i = i -1
    end

    -- remove collectibles
    local i = #collectibles
    while i > -1 do
        if collectibles[i] and collectibles[i].collider and collectibles[i].collider.destroy then
            collectibles[i].collider:destroy()
        end
        table.remove(collectibles, i)
        i = i -1
    end
end

function loadMap(level)
    destroyAll()
    currentLevel = level
    gameMap = sti("maps/testMap".. level ..".lua")

    -- draw wall colliders
    spawnWalls()

    -- draw collectible colliders
    spawnCollectibles()

    -- draw door colliders
    spawnDoors()

    --reset player position
    player.collider:setPosition(playerStartX, playerStartY)
end


function love.update(dt)
    if gameState == 1 then
        if love.keyboard.isDown("space") then
            -- Reset everything needed for a new game
            gameState = 2
            timer = 60
            quakeTimer = 0
            
            -- If player doesn't exist, recreate everything
            if not player then
                -- Recreate player
                player = {}
                player.collider = world:newBSGRectangleCollider(400, 250, 50, 100, 10, {collision_class = "Player"})
                player.collider:setFixedRotation(true)
                player.x = playerStartX
                player.y = playerStartY
                player.speed = 300
                player.spriteSheet1 = love.graphics.newImage('sprites/parrot.png')
                player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
                player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
                
                player.animations = {}
                player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.2)
                player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.2)
                player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.2)
                player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.2)
                player.anim = player.animations.left
                
                -- Reset level and map
                currentLevel = 1
                loadMap(currentLevel)
                
                -- Clear inventory
                inventory = {}
            end
        end
    elseif gameState == 2 then
        -- Only process player-related code if player exists
        if player then
            -- Press 'r' to reload some map, for example
            if love.keyboard.isDown("r") then
                loadMap(2)
            end

            -- 1) Collect the raw direction inputs
            local dx, dy = 0, 0
            if love.keyboard.isDown("right") then
                dx = dx + 1
            end
            if love.keyboard.isDown("left") then
                dx = dx - 1
            end
            if love.keyboard.isDown("down") then
                dy = dy + 1
            end
            if love.keyboard.isDown("up") then
                dy = dy - 1
            end

            -- 2) Normalize so diagonal = same speed as straight lines
            local length = math.sqrt(dx * dx + dy * dy)
            if length > 0 then
                dx, dy = dx / length, dy / length
            end

            -- 3) Multiply by player speed
            local vx = dx * player.speed
            local vy = dy * player.speed

            -- 4) Set which animation to use based on direction
            local isMoving = false
            if dx > 0 then
                player.anim = player.animations.right
                isMoving = true
            elseif dx < 0 then
                player.anim = player.animations.left
                isMoving = true
            elseif dy > 0 then
                player.anim = player.animations.down
                isMoving = true
            elseif dy < 0 then
                player.anim = player.animations.up
                isMoving = true
            end

            -- If player didn't press any movement keys, hold current frame
            if not isMoving then
                player.anim:gotoFrame(2)
            end

            -- Apply velocity using the physics library
            player.collider:setLinearVelocity(vx, vy)

            -- Update the physics world and get the player's actual position
            world:update(dt)
            player.x = player.collider:getX()
            player.y = player.collider:getY()

            -- Animate player
            player.anim:update(dt)

            -- Camera follows the player
            cam:lookAt(player.x, player.y)

            -- if player collects the collectibles
            if player.collider:enter('Collectibles') then
                for i = #collectibles, 1, -1 do
                    local b = collectibles[i]
                    if distanceBetween(b.x, b.y, player.x, player.y) < 100 then
                        if #inventory < maxInventorySlots then
                            table.insert(inventory, b.img)
                        end
                        table.remove(collectibles, i)
                        b.collider:destroy()
                    end
                end
            end

            --TODO if player hits the door send to next level
            if player.collider:enter('Doors') then
                -- Increase the level and load the next map
                loadMap(currentLevel + 1)
            end

            -- Camera border constraints
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
        end

        -- Timer and quake logic (outside of player check)
        if timer > 0 then
            timer = timer - dt
            if timer < 0 then  -- Add this check to prevent timer going negative
                timer = 0
                quakeTimer = quakeDuration
            end
        end

        if quakeTimer > 0 then
            quakeTimer = quakeTimer - dt
            if quakeTimer < 0 then
                quakeTimer = 0
            end
        end

        -- Once quakeTimer <= 0, remove the player collider & set player = nil
        if quakeTimer == 0 and timer == 0 and player then  -- Only destroy player when both timers are 0
            player.collider:destroy()
            player = nil
            gameState = 1  -- Return to main menu
        end
    end
end    


function drawCollectibles()
    for i,c in ipairs(collectibles) do
        love.graphics.draw( c.img, c.x, c.y, nil, nil, 1, 50, 65)
    end
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end

function drawInventory()
    local slotSize = 50
    local startX   = 10
    local startY   = love.graphics.getHeight() - slotSize - 10

    for i = 1, maxInventorySlots do
        local x = startX + (i - 1) * (slotSize + 5)
        love.graphics.rectangle("line", x, startY, slotSize, slotSize)
        love.graphics.print(i, x + slotSize - 10, startY + slotSize - 20)

        if inventory[i] then
            -- Base scale for normal items (50% of original size).
            local baseScale = 0.5

            local itemImage = inventory[i]
            local itemName =
                (itemImage and itemImage.getFilename and itemImage:getFilename())
                or ""

            -- Find the image's original width & height.
            local origW = itemImage:getWidth()
            local origH = itemImage:getHeight()

            -- Start with your base scale.
            local finalScaleX, finalScaleY = baseScale, baseScale

            -- For barrels & crates, make them smaller than normal (e.g., 30% of base).
            if itemName:lower():find("barrel") or itemName:lower():find("crate") then
                finalScaleX = baseScale * 0.3
                finalScaleY = baseScale * 0.3
            end

            -- Center the item in the slot by subtracting half of the final size.
            local offsetX = (origW * finalScaleX) / 2
            local offsetY = (origH * finalScaleY) / 2

            -- Draw with the final scale, centered in the slot.
            love.graphics.draw(
                itemImage,
                x + (slotSize / 2),
                startY + (slotSize / 2),
                0,               -- rotation
                finalScaleX,
                finalScaleY,
                offsetX,
                offsetY
            )
        end
    end
end

function love.draw()
    cam:attach()
        if quakeTimer > 0 then
            local quakeStrength = 8
            quakeOffsetX = love.math.random(-quakeStrength, quakeStrength)
            quakeOffsetY = love.math.random(-quakeStrength, quakeStrength)
            love.graphics.translate(quakeOffsetX, quakeOffsetY)
        else
            quakeOffsetX, quakeOffsetY = 0, 0
        end

        -- Draw map layers
        gameMap:drawLayer(gameMap.layers["Ground"])
        gameMap:drawLayer(gameMap.layers["Trees"])
        gameMap:drawLayer(gameMap.layers["Rooms"])
        drawCollectibles()

        -- Draw player with original offset (6, 9)
        if player then
            player.anim:draw(
                player.spriteSheet,
                player.x,
                player.y,
                nil,
                6,    -- scale X
                nil,
                6,    -- offset X
                9     -- offset Y
            )
        end
    cam:detach()

    -- UI
    if gameState == 2 then
        love.graphics.setFont(timerFont)
        love.graphics.print("Time left for Apocalypse: " .. string.format("%.1f", timer), 10, 10)
    else
        love.graphics.setFont(timerFont)
        love.graphics.print("Press space to start", love.graphics.getWidth()/3, 10)
    end

    drawInventory()
end