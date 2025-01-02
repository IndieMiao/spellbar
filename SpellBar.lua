-- Initialize saved variables
SpellBarSettings = SpellBarSettings or { offset_x = 0, offset_y = 0, scale = 1.2, opacity = 0.7 }

local uiOption = { frame_w = 200,
                   frame_h = 24,
                   offset_x = SpellBarSettings.offset_x,
                   offset_y = SpellBarSettings.offset_y,
                   icon_w = 24,
                   icon_h = 24,
                   padding = 24+1,
                   bgColor = {0.1, 0.1, 0.1, 0.6},
                   spellInCd = { 0.5, 0.5, 1.0, 1},
                   spellReady = { 1, 1, 1, 1},
                   scale = SpellBarSettings.scale,
                   opacity = SpellBarSettings.opacity
}

local SpellBarFrame = CreateFrame("Frame")
SpellBarFrame:SetPoint("CENTER", UIParent, 'CENTER', uiOption.offset_x, uiOption.offset_y)
SpellBarFrame:SetWidth(uiOption.frame_w)
SpellBarFrame:SetHeight(uiOption.frame_h)
SpellBarFrame:Show()

SpellBarFrame:SetScale(uiOption.scale)
SpellBarFrame:SetAlpha(uiOption.opacity)

local function saveFramePosition()
    local point, relativeTo, relativePoint, xOfs, yOfs = SpellBarFrame:GetPoint()
    SpellBarSettings.offset_x = xOfs
    SpellBarSettings.offset_y = yOfs
    SpellBarSettings.scale = uiOption.scale
    SpellBarSettings.opacity = uiOption.opacity
end

local function enableDragging(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        saveFramePosition()
    end)
end

local function disableDragging(frame)
    frame:SetMovable(false)
    frame:EnableMouse(false)
    frame:RegisterForDrag(nil)
    frame:SetScript("OnDragStart", nil)
    frame:SetScript("OnDragStop", nil)
end

local function toggleLock()
    isLocked = not isLocked
    if isLocked then
        disableDragging(SpellBarFrame)
        print("SpellBar frame locked.")
    else
        enableDragging(SpellBarFrame)
        print("SpellBar frame unlocked. Drag to move.")
    end
end

local debugMode = false-- Set to true to enable debug mode
local isLocked = true


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
    {name = "Curse of Doom"},
    {name = "Death Coil"},
    {name = "Conflagrate"},
}

local WARRIOR_SPELL = {
    {name = "Overpower"},
    {name = "Mortal Strike"},
}
local function DebugLog(message)
    DEFAULT_CHAT_FRAME:AddMessage("Spell bar log "..message)
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
    table.insert(timerTexts, timerText)
end

local function initializeSpellsAndItems()
    --OriginSpells = WARLOCK_SPELL

        local _, playerClass = UnitClass("player")
        DebugLog("Player is a :" .. playerClass)
        if playerClass == "SHAMAN" then
            DebugLog("Player is a Shaman")
            OriginSpells = SHAMAN_SPELL
        elseif playerClass == "WARLOCK" then
            OriginSpells = WARLOCK_SPELL
        end

    local totalIcons = 0

    for i, spell in ipairs(OriginSpells) do
        local spellbookId = getSpellBookId(spell.name)
        local spellIcon = GetTexIcon(spell.name,BOOKTYPE_SPELL)
        if spellbookId then
            table.insert(RealSpells, {name = spell.name, id = spellbookId})
            DebugLog("Spell book ID: " ..spellbookId .. " Spell Name: " .. spell.name .. " Spell Icon: " .. spellIcon)
            createIconAndCooldown(SpellBarFrame, spellIcon, totalIcons * uiOption.padding)
            totalIcons = totalIcons + 1
        end
    end
end

local function getTableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

--local totalSpells = getTableLength(OriginSpells)

local function updateCooldowns()
    local totalSpells = getTableLength(RealSpells)
    for i, spell in ipairs(RealSpells) do
        local spellBookId = spell.id
        if spellBookId then
            local start, duration, enable = GetSpellCooldown(spellBookId, BOOKTYPE_SPELL)
            if enable == 1 and duration > 1.5 then
                local remaining = start + duration - GetTime()
                if timerTexts[i] then
                    if remaining > 99 then
                        local minutes = math.floor(remaining / 60)+1
                        timerTexts[i]:SetText("|cff87ffff" .. minutes .. "|r|cffffffffm|r") -- Light blue for number, white for "m"
                    elseif remaining > 3 then
                        timerTexts[i]:SetText("|cffffffff" .. math.ceil(remaining) .. "|r") -- White color
                    else
                        timerTexts[i]:SetText("|cffff0000" .. string.format("%.1f", remaining) .. "|r") -- Red color
                    end
                end
                icons[i]:SetVertexColor(uiOption.spellInCd[1], uiOption.spellInCd[2], uiOption.spellInCd[3], uiOption.spellInCd[4])
            elseif duration <= 1.5 then
                if timerTexts[i] then
                    timerTexts[i]:SetText("")
                end
                icons[i]:SetVertexColor(uiOption.spellReady[1], uiOption.spellReady[2], uiOption.spellReady[3], uiOption.spellReady[4])
            end
        end
    end
end

SpellBarFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
SpellBarFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
SpellBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

SpellBarFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        initializeSpellsAndItems()
    end
    if event == "SPELL_UPDATE_COOLDOWN" then
        updateCooldowns()
    end
end)
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function()
    updateCooldowns()
end)


-- Initialize frame position and lock state
SpellBarFrame:SetPoint("CENTER", UIParent, 'CENTER', uiOption.offset_x, uiOption.offset_y)
if isLocked then
    disableDragging(SpellBarFrame)
else
    enableDragging(SpellBarFrame)
end

local function resetPosition()
    SpellBarSettings.offset_x = 0
    SpellBarSettings.offset_y = -150
    SpellBarSettings.scale = 1
    SpellBarSettings.opacity = 1
    SpellBarFrame:SetPoint("CENTER", UIParent, 'CENTER', SpellBarSettings.offset_x, SpellBarSettings.offset_y)
    SpellBarFrame:SetScale(SpellBarSettings.scale)
    SpellBarFrame:SetAlpha(SpellBarSettings.opacity)
    DebugLog("SpellBar frame position, scale, and opacity reset.")
end

SLASH_SPELLBAR1 = "/spellbar"
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
        initializeSpellsAndItems()
        updateCooldowns()
    elseif command == "lock" then
        isLocked = true
        disableDragging(SpellBarFrame)
        DebugLog("SpellBar frame locked.")
    elseif command == "unlock" then
        isLocked = false
        enableDragging(SpellBarFrame)
        DebugLog("SpellBar frame unlocked. Drag to move.")
    elseif command == "reset" then
        resetPosition()
    elseif command == "scale" then
        local scale = tonumber(value)
        if scale then
            uiOption.scale = scale
            SpellBarFrame:SetScale(scale)
            saveFramePosition()
            DebugLog("SpellBar frame scale set to " .. scale)
        else
            DebugLog("Invalid scale value.")
        end
    elseif command == "opacity" then
        local opacity = tonumber(value)
        if opacity then
            uiOption.opacity = opacity
            SpellBarFrame:SetAlpha(opacity)
            saveFramePosition()
            DebugLog("SpellBar frame opacity set to " .. opacity)
        else
            DebugLog("Invalid opacity value.")
        end
    else
        DebugLog("Unknown command: " .. command)
    end
end