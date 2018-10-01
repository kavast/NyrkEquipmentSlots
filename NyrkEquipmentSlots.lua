-- Show item level and enchants/gems next to character equipment slots

local addonName, addonTable = ...
local select, pairs = select, pairs

-- Level at which missing enchants will be shown as a red icon
local CHECK_ENCHANT_LEVEL = 120

local NUM_ENHANCEMENT_ICONS = MAX_NUM_SOCKETS + 1
local GEM_SLOT_TEXTURE = "Interface\\ITEMSOCKETINGFRAME\\UI-EmptySocket-Prismatic"
local ENCHANTMENT_TEXTURE = "Interface\\ICONS\\Trade_Engraving"

local itemSlotFont = { STANDARD_TEXT_FONT, 10, "OUTLINE" }
local itemSlotLevelTextColor = { 0.8, 0.8, 0.8 }

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

local function UpdateItemSlot(self)

    if (not self.NyrkItemSlotText) then return end

    local iLvlFontString = self.NyrkItemSlotText
    local iLvlText = ""

    local icons = self.nyrkItemEnhancementIcons
    for i = 1, #icons do
        icons[i]:Hide()
    end

    local itemLink = GetInventoryItemLink("player", self:GetID())

    if (itemLink) then

        local item = Item:CreateFromEquipmentSlot(self:GetID())
        local ilevel = item:GetCurrentItemLevel()

        if (ilevel and ilevel > 1) then
            iLvlText = ilevel
        end

        -- get equip location for excluding off-hand
        local equipLoc = select(9, GetItemInfo(itemLink))

        local enchanted = HasEnchantment(itemLink)
        local isMissingEnchantment = self.nyrkCheckEnchant and not enchanted and
                                     equipLoc ~= "INVTYPE_HOLDABLE" and UnitLevel("player") >= CHECK_ENCHANT_LEVEL
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
            
            enchantmentIcon:SetTexture("Interface\\ICONS\\Trade_Engraving")
            if (isMissingEnchantment) then
                enchantmentIcon:SetVertexColor(1, 0.5, 0.5, 1)
            else
                enchantmentIcon:SetVertexColor(1, 1, 1, 1)
            end
            
            enchantmentIcon:Show()
        end
        
        -- Gem sockets
        if (socketCount > 0) then

            local iconIndex = (hasEnchantmentIcon and 2 or 1)

            local gemIcon = self.nyrkItemEnhancementIcons[iconIndex]
            gemIcon:SetTexture(gem1 and GetItemIcon(gem1) or GEM_SLOT_TEXTURE)
            gemIcon:Show()

            if (socketCount > 1) then

                iconIndex = iconIndex + 1

                gemIcon = self.nyrkItemEnhancementIcons[iconIndex]
                gemIcon:SetTexture(gem2 and GetItemIcon(gem2) or GEM_SLOT_TEXTURE)
                gemIcon:Show()

                if (socketCount > 2) then

                    iconIndex = iconIndex + 1

                    gemIcon = self.nyrkItemEnhancementIcons[iconIndex]
                    gemIcon:SetTexture(gem2 and GetItemIcon(gem2) or GEM_SLOT_TEXTURE)
                    gemIcon:Show()
                end
            end
        end
    end

    iLvlFontString:SetText(iLvlText)
end

local function UpdateItemSlots(unit)

    for slotName, slot in pairs(slots) do
        local slotFrame = _G["Character"..slotName]
        UpdateItemSlot(slotFrame)
    end
end

local function InitializeSlots()

    for slotName, slot in pairs(slots) do

        local slotFrame = _G["Character"..slotName]

        if (slotName ~= "ShirtSlot" and slotName ~= "TabardSlot") then

            local itemSlotText = slotFrame:CreateFontString()
            itemSlotText:SetFont(unpack(itemSlotFont))
            itemSlotText:SetVertexColor(unpack(itemSlotLevelTextColor))

            local slotId = GetInventorySlotInfo(slotName)
            local textSide = sides[slot.textSide]
            itemSlotText:SetPoint(textSide.point[1], slotFrame, textSide.point[2], textSide.point[3], textSide.point[4])
            itemSlotText:SetJustifyH(textSide.justifyH)
            
            slotFrame.NyrkItemSlotText = itemSlotText

            if (slot.checkEnchant) then
                slotFrame.nyrkCheckEnchant = true
            end
            
            local icons = {}
            for i = 1, NUM_ENHANCEMENT_ICONS do

                local icon = slotFrame:CreateTexture()
                icon:SetTexture("Interface\\ITEMSOCKETINGFRAME\\UI-EmptySocket-Prismatic")
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                icon:SetSize(12, 12)

                if (i == 1) then
                    icon:SetPoint(textSide.point[1], slotFrame, textSide.point[2], textSide.iconX, -iconYOffset)
                else
                    icon:SetPoint(textSide.point[1], icons[i - 1], textSide.point[2], 0, 0)
                end

                icons[i] = icon
            end

            slotFrame.nyrkItemEnhancementIcons = icons

            UpdateItemSlot(slotFrame)
        end
    end
end
InitializeSlots()

PaperDollItemsFrame:HookScript("OnShow", function()
    UpdateItemSlots("player")
end)

local eventFrame = CreateFrame("Frame")
local events = {}

function events:PLAYER_EQUIPMENT_CHANGED()
    
    if (PaperDollItemsFrame:IsVisible()) then
        UpdateItemSlots("player")
    end
end
-- function events:UNIT_INVENTORY_CHANGED(unit)

--     if (unit == "player" and PaperDollItemsFrame:IsVisible()) then
--         UpdateItemSlots("player")
--     end
-- end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...)
end)

for e, _ in pairs(events) do
    eventFrame:RegisterEvent(e)
end