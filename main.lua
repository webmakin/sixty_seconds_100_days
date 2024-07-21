function love.load()
    json = require 'libraries/json'
    wf = require 'libraries/windfield'
    world = wf.newWorld(0,0)

    world:addCollisionClass('Player'--[[, {ignores = {'Doors'}}]])
    world:addCollisionClass('Walls')
    world:addCollisionClass('Doors')
    world:addCollisionClass('Collectibles')

    camera = require 'libraries/camera'
    cam = camera()
    gameState = 1
    timer = 0
    
 
    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")
    sti = require 'libraries/sti'
    gameMap = sti('maps/testMap2.lua')

    levels = {}

    player = {}
    player.collider = world:newBSGRectangleCollider(400, 250, 50, 100, 10, {collision_class = "Player"})
    player.collider:setFixedRotation(true)
    player.x = 400
    player.y = 200
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

    -- draw wall colliders
    walls = {}
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height, {collision_class = "Walls"})
            wall:setType('static')
            table.insert(walls, wall)
        end
    end

    -- get the collectibles json
    real_collectibles = {
                {
                    name = "crate",
                    img = "objects_03.png",
                    hp = 100    
                },
                {
                    name = "barrel",
                    img = "objects_06.png",
                    hp = 50    
                },
                {
                    name = "barrel",
                    img = "objects_37.png",
                    hp = 80
                }
            }
                

    -- draw collectible colliders
    collectibles = {}
    if gameMap.layers["collectibles"] then
        for i, obj in pairs(gameMap.layers["collectibles"].objects) do
            local collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height, {collision_class = "Collectibles"})
            collider:setType('static')
            local collectible = {}
            collectible.collider = collider
            collectible.x = obj.x
            collectible.y = obj.y
            if real_collectibles[i] then
                local img_sheet = love.graphics.newImage('maps/collectibles1/'..real_collectibles[i].img)
                collectible.img = img_sheet
            else
                collectible.img = player.spriteSheet1
            end
            table.insert(collectibles, collectible)
        end
    end
   
end

function love.update(dt)
    local isMoving = false

    local vx = 0
    local vy = 0
    
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

    --love.graphics.printf("Collider!", 0, 100, 300, "center")
    if  player.collider:enter('Collectibles') then
        for i=#collectibles, 1, -1 do
            local b = collectibles[i]
            if distanceBetween(b.x, b.y, player.x, player.y) < 100 then
                table.remove(collectibles, i)
                b.collider:destroy()
            end
        end
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
    
    timer = timer + dt    
    
end    


function drawCollectibles()
    for i,c in ipairs(collectibles) do
        --local cx, cy = c:getPosition()
        love.graphics.draw( c.img, c.x, c.y, nil, nil, 1, 50, 65)
        --c.anim:draw(sprites.enemySheet, ex, ey, nil, e.direction, 1, 50, 65)
    end
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 )
end

function love.draw()
    --love.graphics.draw(background, 0, 0)
    cam:attach()
        --gameMap:draw()
        gameMap:drawLayer(gameMap.layers["Ground"])
        gameMap:drawLayer(gameMap.layers["Trees"])
        gameMap:drawLayer(gameMap.layers["Rooms"])
        drawCollectibles()
        --gameMap:drawLayer(gameMap.layers["collectibles"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9)
        world:draw()
    cam:detach()
    
   love.graphics.print("Time:" .. string.format("%.2f",  timer), 10, 10 )
end