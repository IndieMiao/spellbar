-- Initialize saved variables

local function DebugLog(message)
    if debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("SPELL_BAR: "..message)
    end
end

local uiOption = { frame_w = 200,
                   frame_h = 24,
                   offset_x = 0,
                   offset_y = -90,
                   icon_w = 24,
                   icon_h = 24,
                   padding = 24+1,
                   bgColor = {0.1, 0.1, 0.1, 0.6},
                   spellInCd = { 0.5, 0.5, 0.5, 1},
                   spellReady = { 1, 1, 1, 1},
                   scale = 1.2,
                   opacity = 0.3
}

local SpellBarFrame = CreateFrame("Frame", "SpellBarFrame", UIParent)
SpellBarFrame:SetPoint("CENTER", uiOption.offset_x, uiOption.offset_y)
SpellBarFrame:SetWidth(uiOption.frame_w)
SpellBarFrame:SetHeight(uiOption.frame_h)
SpellBarFrame:Show()

--local function saveFrameSettings()
--    local point, relativeTo, relativePoint, xOfs, yOfs = SpellBarFrame:GetPoint()
--    DebugLog("Save frame position"..point.." "..relativePoint.." " ..xOfs.." "..yOfs)
--    SpellBarSettings.offset_x = xOfs
--    SpellBarSettings.offset_y = yOfs
--    SpellBarSettings.scale = uiOption.scale
--    SpellBarSettings.opacity = uiOption.opacity
--end

local function reloadFrameSettings()
    SpellBarFrame:SetPoint("CENTER", uiOption.offset_x, uiOption.offset_y)
    SpellBarFrame:SetScale(uiOption.scale)
    SpellBarFrame:SetAlpha(uiOption.opacity)
end

--local function enableDragging(frame)
--    frame:SetMovable(true)
--    frame:EnableMouse(true)
--    frame:RegisterForDrag("LeftButton")
--    frame:SetScript("OnDragStart", function()
--        frame:StartMoving()
--    end)
--    frame:SetScript("OnDragStop", function()
--        frame:StopMovingOrSizing()
--        saveFrameSettings()
--    end)
--end
--
--local function disableDragging(frame)
--    frame:SetMovable(false)
--    frame:EnableMouse(false)
--    frame:RegisterForDrag(nil)
--    frame:SetScript("OnDragStart", nil)
--    frame:SetScript("OnDragStop", nil)
--end

--local function toggleLock()
--    isLocked = not isLocked
--    if isLocked then
--        disableDragging(SpellBarFrame)
--        print("SpellBar frame locked.")
--    else
--        enableDragging(SpellBarFrame)
--        print("SpellBar frame unlocked. Drag to move.")
--    end
--end

local debugMode = false-- Set to true to enable debug mode
--local isLocked = true


local OriginSpells = {}
local RealSpells = {}
local icons = {}
local cooldowns = {}
local timerTexts = {}

local items = {
    {name = "Eye of the Dead"},
}

local SHAMAN_SPELL = {
    {name = "Earth Shock"},
    {name = "Stormstrike"},
    {name = "Lightning Strike"},
    {name = "Chain Lightning"},
    {name = "Earthshaker Slam"},
    {name = "Grounding Totem"},
    {name = "Fire Nova Totem"},
}

local MAGE_SPELL = {
    {name = "Frostbolt"},
    {name = "Evocation"},
    {name = "Arcane Power"},
}

local WARLOCK_SPELL = {
    {name = "Shadowburn"},
    {name = "Soul Fire" },
    {name = "Conflagrate"},
    {name = "Curse of Doom"},
    {name = "Death Coil"},
}

--local WARRIOR_SPELL = {
--    {name = "Overpower"},
--    {name = "Mortal Strike"},
--}


local function getTableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end


local function GetTexIcon(spellname)
    local spellCount = ({GetSpellTabInfo(1)})[4]
    for i = 1, 200 do
        if GetSpellName(i, BOOKTYPE_SPELL) == spellname then
            return GetSpellTexture(i, BOOKTYPE_SPELL)
        end
    end
    return 'Interface\\Icons\\Ability_Seal'
end

local function getSpellBookId(targetSpellName)
    for i = 1, 200 do
        local spellName, spellRank = GetSpellName(i, "spell")
        if spellName == targetSpellName then
            return i
        end
    end
    return nil
end


local function createIconAndCooldown(parent, texture, xOffset)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(texture)
    icon:SetWidth(uiOption.icon_w)
    icon:SetHeight(uiOption.icon_h)
    icon:SetPoint("LEFT", xOffset, 0)
    table.insert(icons, icon)

    local cooldown = CreateFrame("Model", nil, parent, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    table.insert(cooldowns, cooldown)

    local timerText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerText:SetPoint("CENTER", icon, "CENTER")
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Add outline to the font
    timerText:SetShadowOffset(1, -1)
    table.insert(timerTexts, timerText)
end



local function updateCooldowns()
    local totalSpells = getTableLength(RealSpells)
    if totalSpells == 0 then
        return
    end
    for i, spell in ipairs(RealSpells) do
        local spellBookId = spell.id
        if spellBookId then
            local start, duration, enable = GetSpellCooldown(spellBookId, BOOKTYPE_SPELL)
            local inRange = IsSpellInRange(spell.name, "target")
            if enable == 1 and duration > 1.5 then
                local remaining = start + duration - GetTime()
                if timerTexts[i] then
                    if remaining > 99 then
                        local minutes = math.floor(remaining / 60) + 1
                        timerTexts[i]:SetText("|cff87ffff" .. minutes .. "|r|cffffffffm|r") -- Light blue for number, white for "m"
                    elseif remaining > 3 then
                        timerTexts[i]:SetText("|cffffffff" .. math.ceil(remaining) .. "|r") -- White color
                    else
                        timerTexts[i]:SetText("|cffff0000" .. string.format("%.1f", remaining) .. "|r") -- Red color
                    end
                end
                if inRange == 0 then
                    icons[i]:SetVertexColor(1, 0, 0, 1) -- Red color for out of range
                else
                    icons[i]:SetVertexColor(uiOption.spellInCd[1], uiOption.spellInCd[2], uiOption.spellInCd[3], uiOption.spellInCd[4])
                end
            elseif duration <= 1.5 then
                if timerTexts[i] then
                    timerTexts[i]:SetText("")
                end
                if inRange == 0 then
                    icons[i]:SetVertexColor(1, 0, 0, 1) -- Red color for out of range
                else
                    icons[i]:SetVertexColor(uiOption.spellReady[1], uiOption.spellReady[2], uiOption.spellReady[3], uiOption.spellReady[4])
                end
            end
        end
    end
end

local function cleanUp()
    SpellBarFrame:SetScript("OnUpdate", nil) -- Stop the OnUpdate script
    for _, icon in ipairs(icons) do
        icon:Hide()
    end
    for _, cooldown in ipairs(cooldowns) do
        cooldown:Hide()
    end
    for _, timerText in ipairs(timerTexts) do
        timerText:Hide()
    end
    icons = {}
    cooldowns = {}
    timerTexts = {}
    RealSpells = {}
end

local function initializeSpellsAndItems()
    cleanUp()
    local _, playerClass = UnitClass("player")
    if playerClass == "SHAMAN" then
        DebugLog("Player is a Shaman")
        OriginSpells = SHAMAN_SPELL
    elseif playerClass == "WARLOCK" then
        OriginSpells = WARLOCK_SPELL
    end

    local totalIcons = 0
    for i, spell in ipairs(OriginSpells) do
        local spellbookId = getSpellBookId(spell.name)
        local spellIcon = GetTexIcon(spell.name, BOOKTYPE_SPELL)
        if spellbookId then
            table.insert(RealSpells, {name = spell.name, id = spellbookId})
            DebugLog("Spell book ID: " .. spellbookId .. " Spell Name: " .. spell.name .. " Spell Icon: " .. spellIcon)
            totalIcons = totalIcons + 1
        end
    end

    local totalWidth = totalIcons * uiOption.padding
    local startXOffset = (uiOption.frame_w - totalWidth) / 2

    for i, spell in ipairs(RealSpells) do
        createIconAndCooldown(SpellBarFrame, GetTexIcon(spell.name), startXOffset + (i - 1) * uiOption.padding)
    end
end


--local totalSpells = getTableLength(OriginSpells)

reloadFrameSettings()

local function ResetIconAndTimer()
    SpellBarFrame:SetScript("OnUpdate", nil) -- Stop the OnUpdate script
    for _, icon in ipairs(icons) do
        icon:SetVertexColor(1, 1, 1, 1) -- Reset icon color to white
    end
    for _, timerText in ipairs(timerTexts) do
        timerText:SetText("") -- Clear the timer text
    end
end

SpellBarFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
SpellBarFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
SpellBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
SpellBarFrame:RegisterEvent("ADDON_LOADED")
SpellBarFrame:RegisterEvent("CONFIRM_TALENT_WIPE")
-- Register for the PLAYER_REGEN_ENABLED event
SpellBarFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
-- Register for the PLAYER_REGEN_DISABLED event
SpellBarFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

SpellBarFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        initializeSpellsAndItems()
    elseif event == "CONFIRM_TALENT_WIPE" then
        SpellBarFrame:SetScript("OnUpdate", nil)
        cleanUp()
        C_Timer.After(1, function()
            initializeSpellsAndItems()
            if getTableLength(RealSpells) > 0 then
                SpellBarFrame:SetScript("OnUpdate", updateCooldowns)
            end
        end)
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        updateCooldowns()
    elseif event == "PLAYER_REGEN_ENABLED" then
        SpellBarFrame:SetAlpha(uiOption.opacity) -- Fade the frame
        SpellBarFrame:SetScript("OnUpdate", nil) -- Stop the OnUpdate script
        initializeSpellsAndItems()
        ResetIconAndTimer()
    elseif event == "PLAYER_REGEN_DISABLED" then
        initializeSpellsAndItems()
        SpellBarFrame:SetAlpha(0.9) -- Restore frame opacity
        SpellBarFrame:SetScript("OnUpdate", updateCooldowns) -- Start the OnUpdate script
    end
end)



SLASH_SPELLBAR1 = "/spellbar"
SLASH_SPELLBAR1 = "/spb"
SlashCmdList["SPELLBAR"] = function(msg)
    local command, value = "", ""
    local spaceIndex = string.find(msg, " ")
    if spaceIndex then
        command = string.sub(msg, 1, spaceIndex - 1)
        value = string.sub(msg, spaceIndex + 1)
    else
        command = msg
    end


    if command == "debug" then
        debugMode = not debugMode
        DebugLog("Debug mode is now " .. (debugMode and "enabled" or "disabled"))
    elseif command == "reset" then
        DebugLog("Resetting spells and items")
        initializeSpellsAndItems()
    elseif command == "disable" then
        DebugLog("Disabling SpellBar")
        SpellBarFrame:Hide()
        SpellBarFrame:SetScript("OnUpdate", nil)
    elseif command == "enable" then
        DebugLog("Enabling SpellBar")
        initializeSpellsAndItems()
        SpellBarFrame:Show()
        SpellBarFrame:SetScript("OnUpdate", updateCooldowns)
    elseif command == "help" then
        DebugLog("Available commands:")
        DebugLog("/spellbar debug - Toggle debug mode")
        DebugLog("/spellbar reset - Reset spells and items")
        DebugLog("/spellbar disable - Disable the SpellBar")
        DebugLog("/spellbar enable - Enable the SpellBar")
    else
        DebugLog("Unknown command: " .. command)
    end
end