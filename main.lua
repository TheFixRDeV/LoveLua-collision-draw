local tools = require("tools")

function love.load()
    love.window.setMode(1600, 900)
    tools.loadBackground()
    tools.loadVolumes()    
end

function love.update(dt)
    tools.update(dt)
end

function love.mousepressed(x, y, button, istouch)
    tools.mousepressed(x, y, button)
    if button == 2 then 
        tools.startCameraMove()
        end
end

function love.mousereleased(x, y, button, istouch)
    if button == 2 then
        tools.stopCameraMove()
    end
end

function love.keypressed(key)
    if key == "c" then
        tools.cloneSelected()
    elseif key == "x" then  
        tools.deleteSelected()
    elseif key == "escape" then 
        love.event.quit() 
    end
end

function love.quit()
    tools.saveToFile()
end

function isMouseOverButton(btn, x, y)
    return x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height
end

function interface()
    local boxWidth = love.graphics.getWidth()
    local boxHeight = 70
    local boxX = 0
    local boxY = love.graphics.getHeight() - boxHeight

    love.graphics.setColor(0, 0, 0, 0.7) 
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

    local interfaceImagens = {
        { image = love.graphics.newImage("img/button_esc.png"), x = 50,  y = boxY, textLabel = "Esc Save/Quit", textX = 25 },
        { image = love.graphics.newImage("img/button_mb1.png"), x = 150, y = boxY, textLabel = "2x Add Rect", textX = 130 },
        { image = love.graphics.newImage("img/button_mb2.png"), x = 250, y = boxY, textLabel = "2x Add Circle", textX = 230 },
        { image = love.graphics.newImage("img/button_mb2.png"), x = 360, y = boxY, textLabel = "Hold MoveCam", textX = 330 },
        { image = love.graphics.newImage("img/button_awsd.png"), x = 450, y = boxY, textLabel = "Move Selected", textX = 430 },
        { image = love.graphics.newImage("img/button_shift_awsd.png"), x = 545, y = boxY, textLabel = "Scale Selected", textX = 530 },
        { image = love.graphics.newImage("img/button_x.png"), x = 650, y = boxY, textLabel = "Del Selected", textX = 630 },
        { image = love.graphics.newImage("img/button_c.png"), x = 760, y = boxY, textLabel = "Clone Selected", textX = 730 },
    }

    love.graphics.setColor(1, 1, 1) 
    
    for _, item in ipairs(interfaceImagens) do
        love.graphics.draw(item.image, item.x, item.y + 10, 0, 0.5)  
        love.graphics.print(item.textLabel, item.textX, item.y + 50)  
    end

    -- Logs
    local mouseX, mouseY = love.mouse.getPosition()
    local bgMouseX = mouseX + tools.cameraOffsetX
    local bgMouseY = mouseY + tools.cameraOffsetY

    love.graphics.print("World Position: (" .. bgMouseX .. ", " .. bgMouseY .. ")", love.graphics.getWidth() - 180, boxY + 15)
    love.graphics.print("Screen Position: (" .. mouseX .. ", " .. mouseY .. ")", love.graphics.getWidth() - 180, boxY + 45)
    love.graphics.print("Retângulos: " .. #tools.retangulos, love.graphics.getWidth() - 350, boxY + 10)
    love.graphics.print("Círculos: " .. #tools.circulos, love.graphics.getWidth() - 350, boxY + 45)
end

function love.draw()
    tools.draw()
    interface()
end
