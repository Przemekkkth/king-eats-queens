Input = require 'libraries.boipushy.Input'

function love.load()
    FPS = 30 -- frames per second to update the screen
    WINWIDTH = 800 -- width of the program's window, in pixels
    WINHEIGHT = 600 -- height in pixels
    HALF_WINWIDTH = WINWIDTH / 2
    HALF_WINHEIGHT = WINHEIGHT / 2
    
    GRASSCOLOR = {.09, 1., .0} --(24, 255, 0)
    WHITE = {1., 1., 1.} --(255, 255, 255)
    RED = {1., .0, .0}--(255, 0, 0)
    
    CAMERASLACK = 90     -- how far from the center the squirrel moves before moving the camera
    MOVERATE = 9         -- how fast the player moves
    BOUNCERATE = 6       -- how fast the player bounces (large is slower)
    BOUNCEHEIGHT = 30    -- how high the player bounces
    STARTSIZE = 25       -- how big the player starts off
    WINSIZE = 300        -- how big the player needs to be to win
    INVULNTIME = 2       -- how long the player is invulnerable after being hit in seconds
    GAMEOVERTIME = 4     -- how long the "game over" text stays on the screen in seconds
    MAXHEALTH = 3        -- how much health the player starts with
    
    GAMEOVERTXT = "GAME OVER!"
    NUMGRASS = 80        -- number of grass objects in the active area
    NUMSQUIRRELS = 30    -- number of squirrels in the active area
    SQUIRRELMINSPEED = 3 -- slowest squirrel speed
    SQUIRRELMAXSPEED = 7 -- fastest squirrel speed
    DIRCHANGEFREQ = 2    -- % chance of direction change per frame
    LEFT = 'left'
    RIGHT = 'right'
    KING_IMG_R = love.graphics.newImage("assets/sprite/king_r.png")
    KING_IMG_R:setFilter("nearest", "nearest", 1)
    KING_IMG_L = love.graphics.newImage("assets/sprite/king_l.png")
    KING_IMG_L:setFilter("nearest", "nearest", 1)
    QUEEN_IMG_R = love.graphics.newImage("assets/sprite/queen_r.png")
    QUEEN_IMG_R:setFilter("nearest", "nearest", 1)
    QUEEN_IMG_L = love.graphics.newImage("assets/sprite/queen_l.png")
    QUEEN_IMG_L:setFilter("nearest", "nearest", 1)
    GRASSIMAGES = {}
    table.insert(GRASSIMAGES, love.graphics.newImage("assets/sprite/grass1.png"))
    table.insert(GRASSIMAGES, love.graphics.newImage("assets/sprite/grass2.png"))
    table.insert(GRASSIMAGES, love.graphics.newImage("assets/sprite/grass3.png"))
    table.insert(GRASSIMAGES, love.graphics.newImage("assets/sprite/grass4.png"))

    BASICFONT = love.graphics.newFont("assets/font/freesansbold.ttf", 32)
    -- set up variables for the start of a new game
    invulnerableMode = false  -- if the player is invulnerable
    invulnerableStartTime = love.timer.getTime() -- time the player became invulnerable
    gameOverMode = false      -- if the player has lost
    gameOverStartTime = 0     -- time the player lost
    winMode = false           -- if the player has won

    grassObjs = {}    -- stores all the grass objects in the game
    squirrelObjs = {} -- stores all the non-player squirrel objects
    -- stores the player object:
    playerObj = {facing = LEFT,
                 size = STARTSIZE,
                 x = HALF_WINWIDTH,
                 y = HALF_WINHEIGHT,
                 bounce = 0,
                 health = MAXHEALTH}

    moveLeft  = false
    moveRight = false
    moveUp    = false
    moveDown  = false

    camerax = 0
    cameray = 0
    -- start off with some random grass images on the screen
    for i = 1, 10 do 
        table.insert(grassObjs, makeNewGrass(camerax, cameray))
        grassObjs[i].x = love.math.random(0, WINWIDTH)
        grassObjs[i].y = love.math.random(0, WINHEIGHT)
    end

    love.graphics.setBackgroundColor(GRASSCOLOR)
    input = Input()
    input:bind('left',   'left')
    input:bind('a',   'left')
    input:bind('right',   'right')
    input:bind('d',   'right')
    input:bind('up',   'up')
    input:bind('w',   'up')
    input:bind('down',   'down')
    input:bind('s',   'down')
    input:bind('r',   'r')
    input:bind('escape',   'escape')
    input:bind('r',   'r')
    love.window.setMode(WINWIDTH, WINHEIGHT)
    love.window.setTitle('King eats queens')
    sounds = {}
    sounds.coin  = love.audio.newSource("/assets/sound/Coin01.flac" ,"static")
    sounds.hit   = love.audio.newSource("/assets/sound/hit03.mp3.flac" ,"static")
    sounds.music = love.audio.newSource("/assets/music/11._jester_battle.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.25)
    sounds.music:play()
end

function love.update(dt)
    if invulnerableMode and love.timer.getTime() - invulnerableStartTime > INVULNTIME then
        invulnerableMode = false
    end

    -- move all the squirrels
    for _, sObj in ipairs(squirrelObjs) do 
        -- move the squirrel, and adjust for their bounce
        sObj.x = sObj.x + sObj.movex
        sObj.y = sObj.y + sObj.movey
        sObj.bounce = sObj.bounce + 1
        if sObj.bounce > sObj.bouncerate then 
            sObj.bounce = 0 -- reset bounce amount 
        end

        if love.math.random(0, 99) < DIRCHANGEFREQ then 
            sObj.movex = getRandomVelocity()
            sObj.movey = getRandomVelocity()
        end
    end

    for i = #grassObjs, 1, -1 do
        if isOutsideActiveArea(camerax, cameray, grassObjs[i]) then
            table.remove(grassObjs, i) -- Remove the object at index i from the table
        end
    end
    
    -- Iterate over squirrelObjs table
    for i = #squirrelObjs, 1, -1 do
        if isOutsideActiveArea(camerax, cameray, squirrelObjs[i]) then
            table.remove(squirrelObjs, i) -- Remove the object at index i from the table
        end
    end

        -- Add more grass if we don't have enough
    while #grassObjs < NUMGRASS do
        table.insert(grassObjs, makeNewGrass(camerax, cameray))
    end

    -- Add more squirrels if we don't have enough
    while #squirrelObjs < NUMSQUIRRELS do
        table.insert(squirrelObjs, makeNewSquirrel(camerax, cameray))
    end
    
    -- adjust camerax and cameray if beyond the "camera slack"
    local playerCenterx = playerObj.x + math.floor(playerObj.size / 2)
    local playerCentery = playerObj.y + math.floor(playerObj.size / 2)
    if (camerax + HALF_WINWIDTH) - playerCenterx > CAMERASLACK then 
        camerax = playerCenterx + CAMERASLACK - HALF_WINWIDTH
    elseif playerCenterx - (camerax + HALF_WINWIDTH) > CAMERASLACK then
        camerax = playerCenterx - CAMERASLACK - HALF_WINWIDTH
    end
    
    if (cameray + HALF_WINHEIGHT) - playerCentery > CAMERASLACK then
        cameray = playerCentery + CAMERASLACK - HALF_WINHEIGHT  
    elseif playerCentery - (cameray + HALF_WINHEIGHT) > CAMERASLACK then
        cameray = playerCentery - CAMERASLACK - HALF_WINHEIGHT
    end

    handlePlayerInput()

    if not gameOverMode then 
        -- actually move the player
        if moveLeft then
            playerObj.x = playerObj.x - MOVERATE
        end
        if moveRight then
            playerObj.x = playerObj.x + MOVERATE
        end
        if moveUp then
            playerObj.y = playerObj.y - MOVERATE
        end
        if moveDown then
            playerObj.y = playerObj.y + MOVERATE
        end
        if (moveLeft or moveRight or moveUp or moveDown) or playerObj.bounce ~= 0 then
            playerObj.bounce = playerObj.bounce + 1
        end
        if playerObj.bounce > BOUNCERATE then
            playerObj.bounce = 0 -- reset bounce amount
        end

        -- Check if the player has collided with any squirrels
        for i = #squirrelObjs, 1, -1 do
            local sqObj = squirrelObjs[i]
            if checkAABBCollision(sqObj, playerObj) and not winMode then
                -- a player/squirrel collision has occurred
                if sqObj.width * sqObj.height <= playerObj.size^2 then
                    -- player is larger and eats the squirrel
                    playerObj.size = playerObj.size + math.floor((sqObj.width * sqObj.height)^0.2) + 1
                    table.remove(squirrelObjs, i)
                    sounds.coin:stop()
                    sounds.coin:play()

                    if playerObj.size > WINSIZE then
                        winMode = true -- turn on "win mode"
                    end
                elseif not invulnerableMode then
                    sounds.hit:play()
                    -- player is smaller and takes damage
                    invulnerableMode = true
                    invulnerableStartTime = love.timer.getTime()
                    playerObj.health = playerObj.health - 1
                    if playerObj.health == 0 then
                        gameOverMode = true -- turn on "game over mode"
                        gameOverStartTime = love.timer.getTime()
                    end
                end
            end
        end
    end
end

function love.draw()
    for _, obj in ipairs(grassObjs) do 
        love.graphics.draw(obj.grassImage, obj.x - camerax, obj.y - cameray)
    end

    for _, obj in ipairs(squirrelObjs) do
        local width = obj.width / QUEEN_IMG_L:getWidth()
        local height = obj.height / QUEEN_IMG_L:getHeight()
        local image = nil
        local xPos = obj.x - camerax
        local yPos = obj.y - cameray - getBounceAmount(obj.bounce, obj.bouncerate, obj.bounceheight)
        if obj.movex > 0 then 
            image = QUEEN_IMG_R
        else
            image = QUEEN_IMG_L
        end
        love.graphics.draw(image, xPos, yPos, 0, width, height)
    end

    local flashIsOn = math.floor(love.timer.getTime() * 10) % 2 == 1
    if not gameOverMode and not (invulnerableMode and flashIsOn) then 
        local width = playerObj.size / KING_IMG_L:getWidth()
        local height = playerObj.size / KING_IMG_L:getHeight() 
        local image = nil
        local xPos = playerObj.x - camerax
        local yPos = playerObj.y - cameray - getBounceAmount(playerObj.bounce, BOUNCERATE, BOUNCEHEIGHT)
        if playerObj.facing == RIGHT then 
            image = KING_IMG_R
        else
            image = KING_IMG_L
        end
        love.graphics.draw(image, xPos, yPos, 0, width, height)  
    end
    drawHealthMeter(playerObj.health)

    if gameOverMode then
        love.graphics.setFont(BASICFONT)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(GAMEOVERTXT)
        local textHeight = font:getHeight()
        love.graphics.print(GAMEOVERTXT, WINWIDTH / 2, WINHEIGHT / 2, 0, 1, 1, textWidth / 2, textHeight / 2)
    elseif winMode then 
        love.graphics.setFont(BASICFONT)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth("You win!")
        local textHeight = font:getHeight()
        love.graphics.print("You win!", WINWIDTH / 2, WINHEIGHT / 2, 0, 1, 1, textWidth / 2, textHeight / 2)
    end
end

function love.run()
    if love.math then love.math.setRandomSeed(os.time()) end
    if love.load then love.load(arg) end
    if love.timer then love.timer.step() end

    local dt = 0
    local fixed_dt = 1/FPS
    local accumulator = 0

    while true do
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == 'quit' then
                    if not love.quit or not love.quit() then
                        return a
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        accumulator = accumulator + dt
        while accumulator >= fixed_dt do
            if love.update then love.update(fixed_dt) end
            accumulator = accumulator - fixed_dt
        end

        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.0001) end
    end
end

function checkAABBCollision(rect1, rect2)
    return rect1.x < rect2.x + rect2.size and
           rect1.x + rect1.width > rect2.x and
           rect1.y < rect2.y + rect2.size and
           rect1.y + rect1.height > rect2.y
end

function drawHealthMeter(currentHealth)
    for i = 1, currentHealth do
        love.graphics.setColor(RED)
        love.graphics.rectangle("fill", 15, 5 + (10 * MAXHEALTH) - i * 10, 20, 10)
        love.graphics.setColor(1,1,1)
    end

    for i = 1, currentHealth do
        love.graphics.setColor(WHITE)
        love.graphics.rectangle("line", 15, 5 + (10 * MAXHEALTH) - i * 10, 20, 10)
        love.graphics.setColor(1,1,1)
    end
end

function getBounceAmount(currentBounce, bounceRate, bounceHeight)
    -- Returns the number of pixels to offset based on the bounce.
    -- Larger bounceRate means a slower bounce.
    -- Larger bounceHeight means a higher bounce.
    -- currentBounce will always be less than bounceRate
    return math.floor(math.sin((math.pi / bounceRate) * currentBounce) * bounceHeight)
end

function getRandomVelocity()
    local speed = love.math.random(SQUIRRELMINSPEED, SQUIRRELMAXSPEED)
    if love.math.random(0, 1) == 0 then
        return speed
    else
        return -speed
    end
end

function getRandomOffCameraPos(camerax, cameray, objWidth, objHeight)
    local x = love.math.random(camerax - WINWIDTH, camerax + (2 * WINWIDTH))
    local y = love.math.random(cameray - WINHEIGHT, cameray + (2 * WINHEIGHT))

    -- Check if the object is off-camera
    if x + objWidth < camerax or x > camerax + WINWIDTH or y + objHeight < cameray or y > cameray + WINHEIGHT then
        return x, y
    else 
        return 0, 0
    end
end

function handlePlayerInput()
    if input:pressed("up") then 
        moveDown = false
        moveUp = true
    elseif input:pressed("down") then
        moveUp = false
        moveDown = true
    elseif input:pressed("left") then
        moveRight = false
        moveLeft = true
        if playerObj.facing == RIGHT then
            
        end
        playerObj.facing = LEFT
    elseif input:pressed("right") then
        moveLeft  = false
        moveRight = true
        if playerObj.facing == LEFT then

        end
        playerObj.facing = RIGHT
    elseif winMode and input:pressed("r") then
        return
    end

    -- stop moving the player's squirrel
    if input:released('left') then
        moveLeft = false
    elseif input:released('right') then 
        moveRight = false
    elseif input:released('up') then
        moveUp = false
    elseif input:released('down') then
        moveDown = false
    elseif input:released('escape') then
        love.event.quit()
    elseif input:released('r') and winMode then
        reset()
    elseif input:released('r') and gameOverMode then
        reset()
    end

end

function isOutsideActiveArea(camerax, cameray, obj)
    local boundsLeftEdge = camerax - WINWIDTH
    local boundsTopEdge = cameray - WINHEIGHT
    local boundsRect = {x = boundsLeftEdge, y = boundsTopEdge, width = WINWIDTH * 3, height = WINHEIGHT * 3}
    local objRect = {x = obj.x, y = obj.y, width = obj.width, height = obj.height}

    -- Check if the object is outside the active area
    return not (objRect.x + objRect.width > boundsRect.x and
                objRect.x < boundsRect.x + boundsRect.width and
                objRect.y + objRect.height > boundsRect.y and
                objRect.y < boundsRect.y + boundsRect.height)
end

function makeNewSquirrel(camerax, cameray)
    local sq = {}
    local generalSize = love.math.random(5, 25)
    local multiplier = love.math.random(1, 3)
    sq.width =  math.floor( (generalSize + love.math.random(0, 10)) * multiplier )
    sq.height = math.floor( (generalSize + love.math.random(0, 10)) * multiplier )
    sq.x, sq.y = getRandomOffCameraPos(camerax, cameray, sq.width, sq.height)
    sq.movex = getRandomVelocity()
    sq.movey = getRandomVelocity()
    sq.bounce = 0
    sq.bouncerate = love.math.random(10, 18)
    sq.bounceheight = love.math.random(10, 50)
    return sq
end

function makeNewGrass(camerax, cameray)
    local gr = {}
    gr.grassImage =    GRASSIMAGES[love.math.random(1, #GRASSIMAGES)]
    gr.width  = GRASSIMAGES[1]:getWidth()
    gr.height = GRASSIMAGES[1]:getHeight()
    gr.x, gr.y = getRandomOffCameraPos(camerax, cameray, gr.width, gr.height)
    gr.rect = {x = gr.x, y = gr.y, width = gr.width, height = gr.height} 
    return gr
end

function reset()
    playerObj = {facing = LEFT,
    size = STARTSIZE,
    x = HALF_WINWIDTH,
    y = HALF_WINHEIGHT,
    bounce = 0,
    health = MAXHEALTH}

    moveLeft  = false
    moveRight = false
    moveUp    = false
    moveDown  = false

    camerax = 0
    cameray = 0

    winMode = false
    gameOverMode = false
end