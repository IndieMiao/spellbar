local SpellBarFrame = CreateFrame("Frame")
SpellBarFrame:SetPoint("CENTER", UIParent, 'CENTER', 0, -30)
SpellBarFrame:SetWidth(200)
SpellBarFrame:SetHeight(32)
SpellBarFrame:SetBackdrop({bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background'})
SpellBarFrame:SetBackdropColor(1, 1, 0, 1)
SpellBarFrame:Show()

local iconOption = {
    w = 32,
    h = 32,
    padding = 32+1,
}

local debugMode = false-- Set to true to enable debug mode

local spells = {}
local items = {
    {id = 23047, name = "Eye of the Dead"},
}

local SHAMMAN_SPELL = {
    {id = 17364, name = "Stormstrike"},

}

local MAGE_SPELL = {
    {id = 116, name = "Frostbolt"},
    {id = 12051, name = "Evocation"},
    {id = 12042, name = "Arcane Power"},
}

local WARLOCK_SPELL = {
    {id = 18871, name = "Shadowburn"},
    {id = 17924, name = "Soul Fire"},
    {id = 603, name = "Curse of Doom"},
    {id = 17926, name = "Death Coil"},
}

local WARRIOR_SPELL = {
    {id = 7384, name = "Overpower"},
    {id = 12294, name = "Mortal Strike"},
}
local function DebugLog(message)
    DEFAULT_CHAT_FRAME:AddMessage("Spell bar log "..message)
end

local icons = {}
local cooldowns = {}

local function GetTexIcon(spellname)
    local spellCount = ({GetSpellTabInfo(1)})[4]
    for i = 1, spellCount do
        if GetSpellName(i, BOOKTYPE_SPELL) == spellname then
            return GetSpellTexture(i, BOOKTYPE_SPELL)
        end
    end
    return 'Interface\\Icons\\Ability_Seal'
end

local function createIconAndCooldown(parent, texture, xOffset)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(texture)
    icon:SetWidth(iconOption.w)
    icon:SetHeight(iconOption.h)
    icon:SetPoint("LEFT", xOffset, 0)
    table.insert(icons, icon)

    local cooldown = CreateFrame("Frame", nil, parent )
    cooldown:SetAllPoints(icon)
    table.insert(cooldowns, cooldown)
end

local function initializeSpellsAndItems()
    spells = WARLOCK_SPELL

        local _, playerClass = UnitClass("player")
        if playerClass == "Shaman" then
            spells = SHAMMAN_SPELL
        elseif playerClass == "Warlock" then
            DebugLog("Player is a Warlock") 
            spells = WARLOCK_SPELL
        end

    local totalIcons = 0

    for i, spell in ipairs(spells) do
        DebugLog("Spell ID: " .. spell.id .. " Spell Name: " .. spell.name)
        local spellIcon = GetTexIcon(spell.name,BOOKTYPE_SPELL)
        DebugLog("Spell ID: " .. spell.id .. " Spell Name: " .. spell.name .. " Spell Icon: " .. spellIcon)
        createIconAndCooldown(SpellBarFrame, spellIcon, totalIcons * iconOption.padding)
        totalIcons = totalIcons + 1
    end

    --for i, item in ipairs(items) do
    --    local itemIcon = GetItemIcon(item.id)
    --    createIconAndCooldown(SpellBarFrame, itemIcon, totalIcons * 55)
    --    totalIcons = totalIcons + 1
    --end
end

local function updateCooldowns()
    local totalSpells = spells.count;
    for i, spell in ipairs(spells) do
        local start, duration, enable = GetSpellCooldown(spell.name, BOOKTYPE_SPELL)
        if enable == 1 then
            cooldowns[i]:SetCooldown(start, duration)
        end
    end
    --for i, item in ipairs(items) do
    --    local start, duration, enable = GetItemCooldown(item.id)
    --    if enable == 1 then
    --        cooldowns[totalSpells + i]:SetCooldown(start, duration)
    --    end
    --end
end

SpellBarFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
SpellBarFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
SpellBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

SpellBarFrame:SetScript("OnEvent", function()
    if event == "SPELL_UPDATE_COOLDOWN" then
        updateCooldowns()
    elseif event == "BAG_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" then
        updateCooldowns()
        if event == "PLAYER_ENTERING_WORLD" then
            initializeSpellsAndItems()
            DebugLog("Player is a Shaman") 
        end
    end
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
    elseif msg == "Refresh" then
        initializeSpellsAndItems()
        DebugLog("Usage: /spellbar debug - Toggle debug mode to display all Shaman icons")
    end
end