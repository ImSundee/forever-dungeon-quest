-- Forever Dungeon Quests: minimap button
--
-- Hand-rolled rather than pulling in LibDataBroker/LibDBIcon, to keep this
-- addon dependency-free. Uses Blizzard's own built-in quest-giver icon
-- (the yellow "!") instead of a custom texture, since it already reads as
-- "quest" at a glance and needs no image asset to ship.

FDQ_DB = FDQ_DB or {}
FDQ_DB.minimapAngle = FDQ_DB.minimapAngle or 215 -- default: lower-left of the minimap

local RADIUS = 80 -- distance from minimap center, in pixels

local button = CreateFrame("Button", "FDQ_MinimapButton", Minimap)
button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")

local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("CENTER", 0, 0)
icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")

local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local function UpdatePosition()
  local angle = math.rad(FDQ_DB.minimapAngle)
  local x = math.cos(angle) * RADIUS
  local y = math.sin(angle) * RADIUS
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

button:SetScript("OnDragStart", function(self)
  self:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    FDQ_DB.minimapAngle = math.deg(math.atan2(py - my, px - mx))
    UpdatePosition()
  end)
end)

button:SetScript("OnDragStop", function(self)
  self:SetScript("OnUpdate", nil)
end)

button:SetScript("OnClick", function()
  FDQ:ToggleUI()
end)

button:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText("Forever Dungeon Quests")
  GameTooltip:AddLine("Click to check dungeon quests.", 1, 1, 1)
  GameTooltip:AddLine("Drag to move this button.", 0.7, 0.7, 0.7)
  GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

UpdatePosition()
