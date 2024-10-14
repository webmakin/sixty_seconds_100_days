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
    timer = 0
    currentLevel = 1
    
    timer = 60
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

    shake = 0
    shake_duration = 0
    shake_intensity = 0
    
    walls = {}
    doors = {}
    collectibles = {}
    loadMap(currentLevel)
   
end

function spawnWalls()
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height, {collision_class = "Walls"})
            wall:setType('static')
            table.insert(walls, wall)
        end
    end
end

function spawnDoors()
    if gameMap.layers["doors"] then
        for i, obj in pairs(gameMap.layers["doors"].objects) do
            local door = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height, {collision_class = "Doors"})
            door:setType('static')
            table.insert(doors, door)
        end
    end
end

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
    local isMoving = false

    local vx = 0
    local vy = 0
    
    if gameState == 2 then

        if love.keyboard.isDown("r") then
            loadMap(2)
        end

        if love.keyboard.isDown("right") then
            vx = player.speed
            player.anim = player.animations.right
            isMoving = true
        end

        if love.keyboard.isDown("left") then
            vx = player.speed * -1
            player.anim = player.animations.left
            isMoving = true
        end

        if love.keyboard.isDown("down") then
            vy = player.speed
            player.anim = player.animations.down
            isMoving = true
        end

        if love.keyboard.isDown("up") then
            vy = player.speed * -1
            player.anim = player.animations.up
            isMoving = true
        end
    end

    -- if on main menu start the game if space is pressed
    if gameState == 1 then
        if love.keyboard.isDown("space") then
           gameState = 2
        end
    end

    player.collider:setLinearVelocity(vx, vy)

    if isMoving == false then
        player.anim:gotoFrame(2)
    end

    world:update(dt)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    --animations update
    player.anim:update(dt)

    --camera attaching the player
    cam:lookAt(player.x, player.y)

    -- if player collects the collectibles
    if  player.collider:enter('Collectibles') then
        for i=#collectibles, 1, -1 do
            local b = collectibles[i]
            if distanceBetween(b.x, b.y, player.x, player.y) < 100 then
                table.remove(collectibles, i)
                b.collider:destroy()
            end
        end
    end

    -- If player hits the door send to next level
    if player.collider:enter('Doors') then
        -- Increase the level and load the next map
        loadMap(currentLevel + 1)
    end

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
    
    if timer > 0 and gameState == 2 then
        timer = timer - dt  
    end

    if timer <= 0 then
        timer = 0
        startShake(0.1, 3)
    end
    updateShake(dt)

end    


function drawCollectibles()
    for i,c in ipairs(collectibles) do
        love.graphics.draw( c.img, c.x, c.y, nil, nil, 1, 50, 65)
    end
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end

function love.draw()
    -- Apply screen shake
    local dx, dy = 0, 0
    if shake > 0 then
        dx = love.math.random(-shake_intensity, shake_intensity)
        dy = love.math.random(-shake_intensity, shake_intensity)
    end
    
    love.graphics.push()
    love.graphics.translate(dx, dy)

    cam:attach()
    -- Check if each layer exists before drawing
    if gameMap.layers["Ground"] then
       gameMap:drawLayer(gameMap.layers["Ground"])
    end
    if gameMap.layers["Trees"] then
        gameMap:drawLayer(gameMap.layers["Trees"])
    end
    if gameMap.layers["Rooms"] then
        gameMap:drawLayer(gameMap.layers["Rooms"])
    end
    if gameMap.layers["Furniture"] then
        gameMap:drawLayer(gameMap.layers["Furniture"])
    end
    drawCollectibles()
    if gameState == 2 then
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9)
    end
    cam:detach()
    love.graphics.pop()

    -- Draw UI elements that shouldn't shake
    if gameState == 2 then
        love.graphics.setFont(timerFont) 
        love.graphics.print("Time left for Apocalypse : " .. string.format("%d",  math.ceil(timer)), 10, 10) 
        -- if math.ceil(timer) == 0 then
        --     startShake(0.5, 5) 
        -- end           
    else    
        love.graphics.setFont(timerFont) 
        love.graphics.print("Press space to start ", love.graphics.getWidth()/3, 10)                 
    end
end

function startShake(duration, intensity)
    shake = 1
    shake_duration = duration
    shake_intensity = intensity
end

function updateShake(dt)
    if shake > 0 then
        shake = shake - dt / shake_duration
        if shake <= 0 then
            -- Restart the shake immediately
            startShake(0.1, 3)
        end
    end
end