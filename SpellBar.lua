local uiOption = { frame_w = 200,
                   frame_h = 24,
                   offset_x = 0,
                   offset_y = -150,
                   icon_w = 24,
                   icon_h = 24,
                   padding = 24+1,
                   bgColor = {0.1, 0.1, 0.1, 0.6},
                   spellInCd = { 0.2, 0.2, 0.8, 1},
                   spellReady = { 1, 1, 1, 1},
}

local SpellBarFrame = CreateFrame("Frame")
SpellBarFrame:SetPoint("CENTER", UIParent, 'CENTER', uiOption.offset_x, uiOption.offset_y)
SpellBarFrame:SetWidth(uiOption.frame_w)
SpellBarFrame:SetHeight(uiOption.frame_h)
--SpellBarFrame:SetBackdrop({bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background'})
--SpellBarFrame:SetBackdropColor(uiOption.bgColor[1], uiOption.bgColor[2], uiOption.bgColor[3], uiOption.bgColor[4])
SpellBarFrame:Show()


local debugMode = false-- Set to true to enable debug mode

local OriginSpells = {}
local RealSpells = {}
local icons = {}
local cooldowns = {}
local timerTexts = {}

local items = {
    {name = "Eye of the Dead"},
}

local SHAMMAN_SPELL = {
    {name = "Stormstrike"},

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
    OriginSpells = WARLOCK_SPELL

        local _, playerClass = UnitClass("player")
        if playerClass == "Shaman" then
            OriginSpells = SHAMMAN_SPELL
        elseif playerClass == "Warlock" then
            DebugLog("Player is a Warlock") 
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

-- Slash command to toggle debug mode and display all Shaman icons
SLASH_SPELLBAR1 = "/spellbar"
SlashCmdList["SPELLBAR"] = function(msg)
    if msg == "debug" then
        debugMode = not debugMode
        DebugLog("Debug mode is now " .. (debugMode and "enabled" or "disabled"))
        -- Reinitialize spells and items to reflect the change in debug mode
        initializeSpellsAndItems()
        updateCooldowns()
    end
end