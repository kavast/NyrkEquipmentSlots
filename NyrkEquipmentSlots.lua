-- Show item level and enchants/gems next to character equipment slots

local addonName, addonTable = ...
local select, pairs = select, pairs

-- Level at which missing enchants will be shown as a red icon
local CHECK_ENCHANT_LEVEL = 120

local NUM_ENHANCEMENT_ICONS = MAX_NUM_SOCKETS + 1
local GEM_SLOT_TEXTURE = "Interface\\ITEMSOCKETINGFRAME\\UI-EmptySocket-Prismatic"
local ENCHANTMENT_TEXTURE = "Interface\\ICONS\\Trade_Engraving"
local OVERLAY_TEXTURE = "Interface\\AddOns\\"..addonName.."\\IconOverlay"

local itemSlotFont = { STANDARD_TEXT_FONT, 10, "OUTLINE" }
local itemSlotLevelTextColor = { 0.8, 0.8, 0.8 }

local frameSlotPrefixes = {
    ["PaperDollItemsFrame"] = "Character",
    ["InspectPaperDollItemsFrame"] = "Inspect",
}

local slots = {
    ["HeadSlot"] = {
        textSide = "right"
    },
    ["NeckSlot"] = {
        textSide = "right"
    },
    ["ShoulderSlot"] = {
        textSide = "right"
    },
    ["BackSlot"] = {
        textSide = "right",
    },
    ["ChestSlot"] = {
        textSide = "right"
    },
    ["ShirtSlot"] = {
        textSide = "right"
    },
    ["TabardSlot"] = {
        textSide = "right"
    },
    ["WristSlot"] = {
        textSide = "right"
    },
    ["MainHandSlot"] = {
        textSide = "left",
        checkEnchant = true,
    },
    ["SecondaryHandSlot"] = {
        textSide = "right",
        checkEnchant = true,
    },
    ["HandsSlot"] = {
        textSide = "left"
    },
    ["WaistSlot"] = {
        textSide = "left"
    },
    ["LegsSlot"] = {
        textSide = "left"
    },
    ["FeetSlot"] = {
        textSide = "left"
    },
    ["Finger0Slot"] = {
        textSide = "left",
        checkEnchant = true,
    },
    ["Finger1Slot"] = {
        textSide = "left",
        checkEnchant = true,
    },
    ["Trinket0Slot"] = {
        textSide = "left"
    },
    ["Trinket1Slot"] = {
        textSide = "left"
    }
}

local sides = {
    right = {
        point = { "LEFT", "RIGHT", 8, 0 },
        justifyH = "LEFT",
        iconX = 10,
    },
    left = {
        point = { "RIGHT", "LEFT", -7, 0 },
        justifyH = "RIGHT",
        iconX = -10,
    }
}
-- Offset when enchant/gem icons are shown
local iconYOffset = 8


local function GetGemID(itemLink, gemIndex)

    local _, gemLink = GetItemGem(itemLink, gemIndex)
    return gemLink and gemLink:match("item:(%d+)") or nil
end

local function GetSockets(itemLink)

    local stats = GetItemStats(itemLink)

    if (not stats) then return nil end

    local socketCount = stats.EMPTY_SOCKET_PRISMATIC or 0

    local gem1 = GetGemID(itemLink, 1)
    local gem2 = GetGemID(itemLink, 2)
    local gem3 = GetGemID(itemLink, 3)

    return socketCount, gem1, gem2, gem3
end

local function HasEnchantment(itemLink)

    local enchantId = itemLink:match("item:%d+:(%d*)")

    if (enchantId and enchantId ~= "") then
        return true
    else
        return false
    end
end

local function UpdateItemSlot(self, unit)

    if (not self.NyrkItemSlotText) then return end

    local iLvlFontString = self.NyrkItemSlotText
    local iLvlText = ""

    local icons = self.nyrkItemEnhancementIcons
    for i = 1, #icons do
        icons[i]:Hide()
    end

    local itemLink = GetInventoryItemLink(unit, self:GetID())

    if (itemLink) then

        local item

        if (UnitIsUnit(unit, "player")) then
            item = Item:CreateFromEquipmentSlot(self:GetID())
        else
            -- Item not created from location doesn't always return correct ilvl
            item = Item:CreateFromItemLink(itemLink)
        end

        local ilevel = item:GetCurrentItemLevel()
        
        if (ilevel and ilevel > 1) then
            iLvlText = ilevel
        end

        -- get equip location for excluding off-hand
        local equipLoc = select(9, GetItemInfo(itemLink))

        local enchanted = HasEnchantment(itemLink)
        local isMissingEnchantment = self.nyrkCheckEnchant and not enchanted and
                                     equipLoc ~= "INVTYPE_HOLDABLE" and UnitLevel(unit) >= CHECK_ENCHANT_LEVEL
        local hasEnchantmentIcon = enchanted or isMissingEnchantment
        
        local socketCount, gem1, gem2, gem3 = GetSockets(itemLink)

        local point, relativeTo, relativePoint, xOffset = iLvlFontString:GetPoint()
        if (hasEnchantmentIcon or socketCount > 0) then
            iLvlFontString:SetPoint(point, relativeTo, relativePoint, xOffset, iconYOffset)
        else
            iLvlFontString:SetPoint(point, relativeTo, relativePoint, xOffset, 0)
        end
        
        -- Enchantment
        if (hasEnchantmentIcon) then
            
            local enchantmentIcon = self.nyrkItemEnhancementIcons[1]
            
            enchantmentIcon.Icon:SetTexture("Interface\\ICONS\\Trade_Engraving")
            if (isMissingEnchantment) then
                enchantmentIcon.Icon:SetVertexColor(1, 0.5, 0.5, 1)
            else
                enchantmentIcon.Icon:SetVertexColor(1, 1, 1, 1)
            end
            enchantmentIcon.IconOverlay:SetShown(isMissingEnchantment)
            
            enchantmentIcon:Show()
        end
        
        -- Gem sockets
        if (socketCount > 0) then

            local iconIndex = (hasEnchantmentIcon and 2 or 1)

            local gemIcon = self.nyrkItemEnhancementIcons[iconIndex]
            gemIcon.Icon:SetTexture(gem1 and GetItemIcon(gem1) or GEM_SLOT_TEXTURE)
            gemIcon:Show()
            gemIcon.IconOverlay:SetShown(not gem1)

            if (socketCount > 1) then

                iconIndex = iconIndex + 1

                gemIcon = self.nyrkItemEnhancementIcons[iconIndex]
                gemIcon.Icon:SetTexture(gem2 and GetItemIcon(gem2) or GEM_SLOT_TEXTURE)
                gemIcon:Show()
                gemIcon.IconOverlay:SetShown(not gem2)

                if (socketCount > 2) then

                    iconIndex = iconIndex + 1

                    gemIcon = self.nyrkItemEnhancementIcons[iconIndex]
                    gemIcon.Icon:SetTexture(gem2 and GetItemIcon(gem3) or GEM_SLOT_TEXTURE)
                    gemIcon:Show()
                    gemIcon.IconOverlay:SetShown(not gem3)
                end
            end
        end
    end

    iLvlFontString:SetText(iLvlText)
end

local function UpdateItemSlots(frame, unit)

    local slotNamePrefix = frameSlotPrefixes[frame:GetName()]

    for slotName, slot in pairs(slots) do
        local slotFrame = _G[slotNamePrefix..slotName]
        UpdateItemSlot(slotFrame, unit)
    end
end

local function IconOverlaySetPlaying(self, play)

    if (play) then
        if (not self.AnimationGroup:IsPlaying()) then
            self.AnimationGroup:Play()
        end
    else
        self.AnimationGroup:Stop()
    end
end

local function CreateItemEnhancementIcon(slotFrame)
    
    local enhancementIcon = CreateFrame("Frame", nil, slotFrame)
    enhancementIcon:SetSize(12, 12)

    local icon = enhancementIcon:CreateTexture()
    icon:SetTexture(GEM_SLOT_TEXTURE)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetAllPoints()
    enhancementIcon.Icon = icon

    local overlay = enhancementIcon:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture(OVERLAY_TEXTURE)
    overlay:SetSize(16, 16)
    overlay:SetPoint("CENTER")
    overlay:SetVertexColor(1, 0, 0, 1)
    overlay:SetBlendMode("ADD")
    overlay:Hide()
    enhancementIcon.IconOverlay = overlay

    -- ANIMATION
    overlay.AnimationGroup = overlay:CreateAnimationGroup()
    overlay.AnimationGroup:SetLooping("REPEAT")

    local scaleAnim = overlay.AnimationGroup:CreateAnimation("Scale")
    scaleAnim:SetScale(1.5, 1.5)
    scaleAnim:SetDuration(1.25)
    scaleAnim:SetSmoothing("OUT")

    local alphaAnim = overlay.AnimationGroup:CreateAnimation("Alpha")
    alphaAnim:SetFromAlpha(1)
    alphaAnim:SetToAlpha(0)
    alphaAnim:SetDuration(1.15)
    alphaAnim:SetStartDelay(0.1)

    hooksecurefunc(overlay, "SetShown", IconOverlaySetPlaying)

    return enhancementIcon
end

local function InitializeSlots(frame)

    local slotNamePrefix = frameSlotPrefixes[frame:GetName()]

    for slotName, slot in pairs(slots) do

        local slotFrame = _G[slotNamePrefix..slotName]

        if (slotName ~= "ShirtSlot" and slotName ~= "TabardSlot") then

            local itemSlotText = slotFrame:CreateFontString()
            itemSlotText:SetFont(unpack(itemSlotFont))
            itemSlotText:SetVertexColor(unpack(itemSlotLevelTextColor))

            local textSide = sides[slot.textSide]
            itemSlotText:SetPoint(textSide.point[1], slotFrame, textSide.point[2], textSide.point[3], textSide.point[4])
            itemSlotText:SetJustifyH(textSide.justifyH)
            
            slotFrame.NyrkItemSlotText = itemSlotText

            if (slot.checkEnchant) then
                slotFrame.nyrkCheckEnchant = true
            end
            
            local icons = {}
            for i = 1, NUM_ENHANCEMENT_ICONS do

                local icon = CreateItemEnhancementIcon(slotFrame)
                
                if (i == 1) then
                    icon:SetPoint(textSide.point[1], slotFrame, textSide.point[2], textSide.iconX, -iconYOffset)
                else
                    icon:SetPoint(textSide.point[1], icons[i - 1], textSide.point[2], 0, 0)
                end

                icons[i] = icon
            end

            slotFrame.nyrkItemEnhancementIcons = icons
        end
    end
end

local function InitializeCharacterFrame()

    InitializeSlots(PaperDollItemsFrame)

    PaperDollItemsFrame:HookScript("OnShow", function()
        UpdateItemSlots(PaperDollItemsFrame, "player")
    end)
end

local function InitializeInspectFrame()

    InitializeSlots(InspectPaperDollItemsFrame)

    InspectPaperDollItemsFrame:HookScript("OnShow", function()
        UpdateItemSlots(InspectPaperDollItemsFrame, InspectFrame.unit)
    end)
end


local eventFrame = CreateFrame("Frame")
local events = {}

function events:PLAYER_LOGIN()
    
    InitializeCharacterFrame()
    eventFrame:UnregisterEvent("PLAYER_LOGIN")

    if (IsAddOnLoaded("Blizzard_InspectUI")) then
        InitializeInspectFrame()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end
function events:ADDON_LOADED(addon)
    
    if (addon == "Blizzard_InspectUI") then
        InitializeInspectFrame()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end
function events:PLAYER_EQUIPMENT_CHANGED()
    
    if (PaperDollItemsFrame:IsVisible()) then
        UpdateItemSlots(PaperDollItemsFrame, "player")
    end

    -- PLAYER_EQUIPMENT_CHANGED is more accurate than UNIT_INVENTORY_CHANGED, so update self inspect here.
    -- UNIT_INVENTORY_CHANGED doesn't seem to fire when switching an item with the same item,
    -- even if their stats are different.
    if (InspectFrame and InspectPaperDollItemsFrame:IsVisible() and UnitIsUnit(InspectFrame.unit, "player")) then
        UpdateItemSlots(InspectPaperDollItemsFrame, "player")
    end
end
function events:UNIT_INVENTORY_CHANGED(unit)

    -- Player is updated in PLAYER_EQUIPMENT_CHANGED
    if (UnitIsUnit(unit, "player") or not InspectFrame) then return end

    if (InspectPaperDollItemsFrame:IsVisible() and unit == InspectFrame.unit) then
        UpdateItemSlots(InspectPaperDollItemsFrame, unit)
    end
end
function events:INSPECT_READY()
    events:UNIT_INVENTORY_CHANGED(InspectFrame.unit)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...)
end)

for e, _ in pairs(events) do
    eventFrame:RegisterEvent(e)
end