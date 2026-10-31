    local bar = panel and panel:FindFirstChild("Bar")
    local amount = bar and bar:FindFirstChild("Amount")
    local progress = amount and amount.Text
    if not progress then return end
    local current, maximum = string.match(progress, "(%d+)%s*/%s*(%d+)")
    if current and maximum then
        collected, total = tonumber(current), tonumber(maximum)
        if progress ~= lastProgress then
            lastProgress = progress
            print("Halloween Ghosts:", collected .. "/" .. total, "Remaining:", total - collected)
        end
    end
end
local function makeESP(key)
    local label = Drawing.new("Text")
    label.Text, label.Size, label.Center, label.Outline = "Ghost", 16, true, true
    label.Color, label.Visible = espColor, false
    local line = Drawing.new("Line")
    line.Color, line.Thickness, line.Visible = espColor, 1, false
    cache[key] = {label = label, line = line}
end
local function hideESP(esp)
    esp.label.Visible, esp.line.Visible = false, false
end
local function updateESP()
    local camera = workspace.CurrentCamera
    local event = workspace:FindFirstChild("HalloweenEvent")
    local folder = event and event:FindFirstChild("Ghosts")
    if not setting("ur_ghost_esp", false) or not camera or not folder then
        for _, esp in pairs(cache) do hideESP(esp) end
        return
    end
    local active = {}
    for _, ghost in ipairs(folder:GetChildren()) do
        if ghost.Name == "Ghost" then
            local key = tostring(ghost:GetAttribute("GhostId") or ghost)
            active[key] = true
            if not cache[key] then makeESP(key) end
            local esp = cache[key]
            local body = ghost:FindFirstChild("Body") or ghost:FindFirstChild("Eyes")
            if body then
                local distance = (body.Position - camera.CFrame.Position).Magnitude
                local screen, visible = WorldToScreen(body.Position)
                if visible and distance <= setting("ur_ghost_range", 1500) then
                    local label = "Ghost #" .. key
                    if setting("ur_ghost_distance", true) then
                        label = label .. string.format(" [%d studs]", math.floor(distance))
                    end
                    esp.label.Text = label
                    esp.label.Position = Vector2.new(screen.X, screen.Y - 25)
                    esp.label.Color, esp.label.Visible = espColor, true
                    if setting("ur_ghost_lines", false) then
                        esp.line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        esp.line.To = Vector2.new(screen.X, screen.Y)
                        esp.line.Color, esp.line.Visible = espColor, true
                    else
                        esp.line.Visible = false
                    end
                else hideESP(esp) end
            else hideESP(esp) end
        end
    end
    for key, esp in pairs(cache) do
        if not active[key] then
            esp.label:Remove()
            esp.line:Remove()
            cache[key] = nil
        end
    end
end
local lastCompensation = 0
local function updateRecoil()
    if not setting("ur_recoil", false) or not isrbxactive() or setting("ur_farm", false) then return end
    if setting("ur_recoil_firing", true) and not ismouse1pressed() then return end
    local now = os.clock()
    if now - lastCompensation < setting("ur_recoil_interval", 0.02) then return end
    lastCompensation = now
    mousemoverel(0, setting("ur_recoil_strength", 1.5))
end
local instantReloadWasEnabled = false
local function applyInstantReload(container)
    if not container then return end
    for _, item in pairs(container:GetChildren()) do
        local value = item:GetAttribute("ReloadTime")
        if type(value) == "number" then
            if originalReloadTimes[item] == nil then originalReloadTimes[item] = value end
            if value ~= 0 then item:SetAttribute("ReloadTime", 0) end
        end
    end
end
local function updateInstantReload()
    local enabled = setting("ur_instant_reload", false)
    if enabled then
        applyInstantReload(player:FindFirstChild("Backpack"))
        applyInstantReload(player.Character)
    elseif instantReloadWasEnabled then
        for item, value in pairs(originalReloadTimes) do
            pcall(function() item:SetAttribute("ReloadTime", value) end)
            originalReloadTimes[item] = nil
        end
    end
    instantReloadWasEnabled = enabled
end
print("Urban Reload Hub V2.6 loaded")
while true do
    local ok, err = pcall(function()
        updateAutofarm()
        updateProgress()
        updateESP()
        updateInstantReload()
        updateRecoil()
    end)
    if not ok and err ~= lastError then
        print("Hub error:", tostring(err))
        lastError = err
    end
    task.wait(0.02)
end
