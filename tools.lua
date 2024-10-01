local tools = {}
tools.retangulos = {}
tools.circulos = {}
tools.selecionado = nil
tools.estado = 'inicial'

-- Config cam
tools.cameraOffsetX = 0
tools.cameraOffsetY = 0
tools.prevMouseX = 0
tools.prevMouseY = 0
tools.mouseOffsetX = 0
tools.mouseOffsetY = 0
tools.movingCamera = false

-- Config interface
tools.backgroundImage = nil
tools.lastClickTime = 0
tools.clickDelay = 0.25

tools.nextID = { retangulo = 0, circulo = 0 }
tools.scaleFactor = 5

-- Toodo: Fix automatic save mensage (autosave,work)
tools.isSaving = false
tools.savingMessage = nil
tools.saveStartTime = nil
tools.autoSaveTimer = 0
tools.autoSaveInterval = 60

function tools.loadBackground()
    tools.backgroundImage = love.graphics.newImage("background.png") --exemplo tile by:MetaruPX
    tools.backgroundWidth = tools.backgroundImage:getWidth()
    tools.backgroundHeight = tools.backgroundImage:getHeight()
end

function tools.loadVolumes()
    local file = io.open("volumes.txt", "r")
    if file then
        tools.retangulos = {}
        tools.circulos = {}
        for line in file:lines() do
            local id, x, y, largura, altura = line:match("id = (%d+), x = (%d+), y = (%d+), width = (%d+), height = (%d+)")
            if id and x and y and largura and altura then
                local novoRetangulo = {
                    id = tonumber(id),
                    x = tonumber(x),
                    y = tonumber(y),
                    largura = tonumber(largura),
                    altura = tonumber(altura)
                }
                table.insert(tools.retangulos, novoRetangulo)
                tools.nextID.retangulo = math.max(tools.nextID.retangulo, novoRetangulo.id + 1)
            end

            local idCircle, cx, cy, radius = line:match("id = (%d+), x = (%d+), y = (%d+), radius = (%d+)")
            if idCircle and cx and cy and radius then
                local novoCirculo = {
                    id = tonumber(idCircle),
                    x = tonumber(cx),
                    y = tonumber(cy),
                    raio = tonumber(radius)
                }
                table.insert(tools.circulos, novoCirculo)
                tools.nextID.circulo = math.max(tools.nextID.circulo, novoCirculo.id + 1)
            end
        end
        file:close()
    end
end

function tools.mousepressed(x, y, button)
    local mx = x + tools.cameraOffsetX
    local my = y + tools.cameraOffsetY

    local currentTime = love.timer.getTime()

    if currentTime - tools.lastClickTime < tools.clickDelay then
        if button == 1 then  -- Clique esquerdo para criar retângulo
            local novoRetangulo = {
                id = tools.nextID.retangulo,
                x = mx,
                y = my,
                largura = 50,
                altura = 50,
            }
            table.insert(tools.retangulos, novoRetangulo)
            tools.nextID.retangulo = tools.nextID.retangulo + 1
            tools.saveToFile() 
        elseif button == 2 then  -- Clique direito para criar círculo
            local novoCirculo = {
                id = tools.nextID.circulo,
                x = mx,
                y = my,
                raio = 25,
            }
            table.insert(tools.circulos, novoCirculo)
            tools.nextID.circulo = tools.nextID.circulo + 1
            tools.saveToFile() 
        end
    else
        -- Seleciona um retângulo
        for _, r in ipairs(tools.retangulos) do
            if mx >= r.x and mx <= r.x + r.largura and my >= r.y and my <= r.y + r.altura then
                tools.selecionado = r
                tools.mouseOffsetX = mx - r.x
                tools.mouseOffsetY = my - r.y
                tools.estado = 'movendo'
                return
            end
        end
        
        -- Seleciona um círculo
        for _, c in ipairs(tools.circulos) do
            local distance = math.sqrt((mx - c.x) ^ 2 + (my - c.y) ^ 2)
            if distance <= c.raio then
                tools.selecionado = c
                tools.mouseOffsetX = mx - c.x
                tools.mouseOffsetY = my - c.y
                tools.estado = 'movendo'
                return
            end
        end

        tools.selecionado = nil
        tools.estado = 'inicial'
    end

    tools.lastClickTime = currentTime
end

-- Clona o objeto selecionado
function tools.cloneSelected()
    if tools.selecionado then
        local clone
        if tools.selecionado.largura then  -- rect
            clone = {
                id = tools.nextID.retangulo,
                x = tools.selecionado.x + tools.selecionado.largura,
                y = tools.selecionado.y,
                largura = tools.selecionado.largura,
                altura = tools.selecionado.altura
            }
            table.insert(tools.retangulos, clone)
            tools.nextID.retangulo = tools.nextID.retangulo + 1
            
        elseif tools.selecionado.raio then  -- circle
            clone = {
                id = tools.nextID.circulo,
                x = tools.selecionado.x + tools.selecionado.raio * 2,
                y = tools.selecionado.y,
                raio = tools.selecionado.raio
            }
            table.insert(tools.circulos, clone)
            tools.nextID.circulo = tools.nextID.circulo + 1
        end
        tools.saveToFile()
    end
end

function tools.update(dt)
    local mx, my = love.mouse.getPosition()

    if tools.movingCamera then
        local dx = mx - tools.prevMouseX
        local dy = my - tools.prevMouseY
        tools.cameraOffsetX = tools.cameraOffsetX - dx
        tools.cameraOffsetY = tools.cameraOffsetY - dy
        tools.cameraOffsetX = math.max(0, math.min(tools.cameraOffsetX, tools.backgroundWidth - love.graphics.getWidth()))
        tools.cameraOffsetY = math.max(0, math.min(tools.cameraOffsetY, tools.backgroundHeight - love.graphics.getHeight()))
    end

    tools.prevMouseX = mx
    tools.prevMouseY = my

    if tools.selecionado then
        local speed = 100 * dt  -- movespeed
        if not (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
            if love.keyboard.isDown("w") then
                tools.selecionado.y = tools.selecionado.y - speed
            end
            if love.keyboard.isDown("s") then
                tools.selecionado.y = tools.selecionado.y + speed
            end
            if love.keyboard.isDown("a") then
                tools.selecionado.x = tools.selecionado.x - speed
            end
            if love.keyboard.isDown("d") then
                tools.selecionado.x = tools.selecionado.x + speed
            end
        end

        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            local scaleSpeed = 100 * dt  -- scaleSpeed
            if tools.selecionado.raio then  --circle
                if love.keyboard.isDown("w") then
                    tools.selecionado.raio = tools.selecionado.raio + scaleSpeed
                end
                if love.keyboard.isDown("s") then
                    tools.selecionado.raio = math.max(1, tools.selecionado.raio - scaleSpeed)
                end
            elseif tools.selecionado.largura then  --rect
                if love.keyboard.isDown("w") then
                    tools.selecionado.altura = tools.selecionado.altura - scaleSpeed
                end
                if love.keyboard.isDown("s") then
                    tools.selecionado.altura = tools.selecionado.altura + scaleSpeed
                end
                if love.keyboard.isDown("a") then
                    tools.selecionado.largura = tools.selecionado.largura - scaleSpeed
                end
                if love.keyboard.isDown("d") then
                    tools.selecionado.largura = tools.selecionado.largura + scaleSpeed
                end
            end
        end
    end

   --autosave
    tools.autoSaveTimer = tools.autoSaveTimer + dt
    if tools.autoSaveTimer >= tools.autoSaveInterval then
        tools.saveToFile()
        tools.autoSaveTimer = 0
    end

    if tools.isSaving and love.timer.getTime() - tools.saveStartTime > 1 then
        tools.savingMessage = nil
    end
end

-- StarCamMove
function tools.startCameraMove()
    tools.movingCamera = true
end

-- StopCamMove
function tools.stopCameraMove()
    tools.movingCamera = false
end

-- SaveToFile TODO: i need lear how use lib to open window dialog
function tools.saveToFile()
    if not tools.isSaving then
        tools.isSaving = true
        tools.savingMessage = "SALVANDO..."
        tools.saveStartTime = love.timer.getTime()  --todo:fixmensage start 

        local file = io.open("volumes.txt", "w")
        if file then
            file:write("-- Retângulos\n")
            for _, r in ipairs(tools.retangulos) do
                file:write(string.format("{ id = %d, x = %d, y = %d, width = %d, height = %d },\n", r.id, r.x, r.y, r.largura, r.altura))
            end

            file:write("-- Círculos\n")
            for _, c in ipairs(tools.circulos) do
                file:write(string.format("{ id = %d, x = %d, y = %d, radius = %d },\n", c.id, c.x, c.y, c.raio))
            end
            file:close()
        end

        tools.savingMessage = "SALVO!"
        tools.isSaving = false
    end
end


--deleteSelectedObject
function tools.deleteSelected()
    if tools.selecionado then
        if tools.selecionado.largura then
            for i, r in ipairs(tools.retangulos) do
                if r == tools.selecionado then
                    table.remove(tools.retangulos, i)
                    tools.selecionado = nil
                    break
                end
            end
        else
            for i, c in ipairs(tools.circulos) do
                if c == tools.selecionado then
                    table.remove(tools.circulos, i)
                    tools.selecionado = nil
                    break
                end
            end
        end
        tools.recreateIDs()
        tools.saveToFile() 
    end
end

-- idUpdate
function tools.recreateIDs()
    local idRetangulo = 0
    for _, r in ipairs(tools.retangulos) do
        r.id = idRetangulo
        idRetangulo = idRetangulo + 1
    end

    local idCirculo = 0
    for _, c in ipairs(tools.circulos) do
        c.id = idCirculo
        idCirculo = idCirculo + 1
    end

    tools.nextID.retangulo = idRetangulo
    tools.nextID.circulo = idCirculo
end


function tools.draw()
    love.graphics.push()
    love.graphics.translate(-tools.cameraOffsetX, -tools.cameraOffsetY)

    if tools.backgroundImage then
        love.graphics.draw(tools.backgroundImage, 0, 0)
    else
        love.graphics.print("Background não encontrado", 100, 100)
    end

    -- rect
    for _, r in ipairs(tools.retangulos) do
        love.graphics.setColor(0, 0, 253, 0.5)
        love.graphics.rectangle('fill', r.x, r.y, r.largura, r.altura)
                love.graphics.setColor(1, 1, 1)


        love.graphics.print(r.id, r.x + 3 + r.largura / 2, r.y + r.altura / 2, 0, 1, 1, 10, 10)
    end

    -- circle
    for _, c in ipairs(tools.circulos) do
        love.graphics.setColor(255, 0, 145, 0.5)
        love.graphics.circle('fill', c.x, c.y, c.raio)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(c.id, c.x + 2, c.y, 0, 1, 1, 10, 10)
    end

    if tools.selecionado then
        love.graphics.setColor(1, 0, 0)
        if tools.selecionado.largura then
            love.graphics.rectangle('line', tools.selecionado.x, tools.selecionado.y, tools.selecionado.largura, tools.selecionado.altura)
        else
            love.graphics.circle('line', tools.selecionado.x, tools.selecionado.y, tools.selecionado.raio)
        end
    end

    love.graphics.pop()
end

return tools
