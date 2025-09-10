if IsDuplicityVersion() then return end

Dial = {}
Keypad = {}
function Dial.Open(id)
    if not id or Dial.Active then return end
    Dial.Active = id
    local p = promise.new()
    CreateThread(function()
        local rotation = 0.0
        local notchCount = 100
        local notchAngle = 360 / notchCount
        local lpressed = false
        local rpressed = false
        local ramp = 0
        local notchIndex = 0
        local lastPressed = nil
        local code = ""
        while Dial.Active do
            Wait(3)
            DisableAllControlActions(0)
            if IsDisabledControlJustPressed(0, 34) then
                rotation = (rotation + notchAngle) % 360 -- much slower
                ramp = 50
                lpressed = true
            end
            if IsDisabledControlJustPressed(0, 35) then
                rotation = (rotation - notchAngle) % 360
                ramp = 50
                rpressed = true
            end

            if IsDisabledControlJustReleased(0, 34) then
                lastPressed = "left"
                lpressed = false
                if ramp <= 0 then
                    rotation = math.ceil((rotation ) / notchAngle) * notchAngle
                end
            end
            if IsDisabledControlJustReleased(0, 35) then
                lastPressed = "right"
                rpressed = false
                if ramp <= 0 then 
                    rotation = math.floor(rotation / notchAngle) * notchAngle
                end
            end

            if lpressed and ramp <= 0 then 
                rotation = (rotation + notchAngle * 0.25) % 360 -- speed up rotation
            end

            if rpressed and ramp <= 0 then
                rotation = (rotation - notchAngle * 0.25) % 360 -- speed up rotation
            end

            if lastPressed == "left" and rpressed then
                lastPressed = ""
                code = code .. "L" .. tostring(notchIndex) .. " "
                
            elseif lastPressed == "right" and lpressed then
                lastPressed = ""
                code = code .. "R" .. tostring(notchIndex) .. " "
            end
            --escape
            if IsDisabledControlJustPressed(0, 177) then
                Dial.Active = nil
                p:resolve(nil)
                break
            end

            --enter 
            if IsDisabledControlJustPressed(0, 176) then
                -- split the code to make sure there are 2 entries
                local entries = {}
                for entry in code:gmatch("%S+") do
                    table.insert(entries, entry)
                end
                if #entries < 2 or #entries > 2 then
                    rotation = 0
                    code = ""
                    Bridge.Notify.SendNotify("Invalid code", "error", 5000)
                    p:resolve(nil)
                    break
                end
            
                if lastPressed == "left" then
                    lastPressed = ""
                    code = code .. "L" .. tostring(notchIndex) .. " "
                elseif lastPressed == "right" then
                    lastPressed = ""
                    code = code .. "R" .. tostring(notchIndex) .. " "
                end
                Dial.Active = nil
                p:resolve(code)
                break
            end
            
            ramp = math.max(0, ramp - 1)
            notchIndex = math.floor(100 - rotation / notchAngle)
            if notchIndex == 100 then notchIndex = 0 end
            local textureDict = "MPSafeCracking"
            local aspectRatio = GetAspectRatio(true)
            DrawSprite(textureDict,"Dial_BG", 0.5, 0.5, 0.3, aspectRatio * 0.3, 0, 255, 255, 255, 255)
            DrawSprite(textureDict,"Dial", 0.5, 0.5, 0.3*0.5, aspectRatio * 0.3 * 0.5, rotation, 255, 255, 255, 255)
        end
        Dial.Active = nil
    end)
    return Citizen.Await(p)
end

function Keypad.Open(id)
    if not id or Dial.Active then return end
    Dial.Active = id
    local result = Bridge.Input.Open("Keypad", {
        {
            type = 'number',
            label = 'code',
            description = 'Enter combination (4 digits)',
            required = true,
            min = 1000,
            max = 9999
        }
    })
    Dial.Active = nil
    return result and result[1] or nil
end

Bridge.Callback.Register("mrc-storage:cb:UseLock", function(id)
    local configLock = Config.Lock[id]
    if not configLock then return end
    if configLock.type == "keypad" then
        local code = Keypad.Open(id)
        return code
    end
    local code = Dial.Open(id)
    return code
end)