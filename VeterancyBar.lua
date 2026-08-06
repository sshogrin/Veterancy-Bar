local ADDON_NAME = "VeterancyBar"

local VeterancyBar = {
    window = nil,
    bar = nil,
    label = nil,
    savedVars = nil,
}

VeterancyBar.defaults = {
    x = 200,
    y = 200

}
------------------------------------------------------------
-- Get current veterancy data
------------------------------------------------------------

local function GetVeterancyProgress()
    local trackType = REWARD_TRACK_TYPE_AVA_VETERANCY
    local trackId = GetActiveReferenceTrackIdsForRewardTrackType(trackType)

    if not trackId then
        return 0, 100, 0
    end

    local trackIndex = GetReferenceTrackIndex(trackType, trackId)

    if not trackIndex then
        return 0, 100, 0
    end

    local _, rank, progress = GetInfoForRewardTrack(trackType, trackIndex)

    local total = GetTotalProgressAtRewardTrackTier(
        GetRewardTrackIdFromReferenceTrackId(trackType, trackId),
        rank
    )

    return progress, (total and total > 0) and total or 100, rank
end

------------------------------------------------------------
-- Update
------------------------------------------------------------

function VeterancyBar.Update()
    local current, max, rank = GetVeterancyProgress()

    VeterancyBar.bar:SetMinMax(0, max)
    VeterancyBar.bar:SetValue(current)

    VeterancyBar.label:SetText(string.format(
        "Vet %d  %d%%",
        rank,
        math.floor(current / max * 100)
    ))
end

------------------------------------------------------------
-- UI
------------------------------------------------------------

function VeterancyBar.CreateUI()
    local wm = WINDOW_MANAGER

    VeterancyBar.window = wm:CreateTopLevelWindow("VeterancyBarWindow")
    VeterancyBar.window:SetDimensions(260, 25)

    VeterancyBar.window:ClearAnchors()
    VeterancyBar.window:SetAnchor(
        TOPLEFT,
        GuiRoot,
        TOPLEFT,
        VeterancyBar.savedVars.x,
        VeterancyBar.savedVars.y
    )

    VeterancyBar.window:SetMovable(true)
    VeterancyBar.window:SetClampedToScreen(true)

    --------------------------------------------------------
    -- Background
    --------------------------------------------------------

    local bg = wm:CreateControl(nil, VeterancyBar.window, CT_BACKDROP)
    bg:SetAnchorFill()
    bg:SetCenterColor(1, 1, 1, 1)

    --------------------------------------------------------
    -- Progress bar
    --------------------------------------------------------

    VeterancyBar.bar = wm:CreateControl(nil, VeterancyBar.window, CT_STATUSBAR)
    VeterancyBar.bar:SetAnchorFill()
    VeterancyBar.bar:SetColor(1, 1, 0, 1)

    --------------------------------------------------------
    -- Label
    --------------------------------------------------------

    VeterancyBar.label = wm:CreateControl(nil, VeterancyBar.window, CT_LABEL)
    VeterancyBar.label:SetAnchor(CENTER, VeterancyBar.window, CENTER)
    VeterancyBar.label:SetFont("ZoFontGameMedium")
    VeterancyBar.label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    VeterancyBar.label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    VeterancyBar.label:SetColor(0.05, 0.05, 0.05, 1)

    --------------------------------------------------------
    -- Drag control
    --------------------------------------------------------

    local dragger = wm:CreateControl(nil, VeterancyBar.window, CT_CONTROL)
    dragger:SetAnchorFill()
    dragger:SetMouseEnabled(true)

    dragger:SetHandler("OnMouseDown", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            VeterancyBar.window:StartMoving()
        end
    end)

    dragger:SetHandler("OnMouseUp", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            VeterancyBar.window:StopMovingOrResizing()

            VeterancyBar.savedVars.x = VeterancyBar.window:GetLeft()
            VeterancyBar.savedVars.y = VeterancyBar.window:GetTop()
        end
    end)
end

------------------------------------------------------------
-- Events
------------------------------------------------------------

local function RefreshAfterActivation()
    VeterancyBar.Update()

    zo_callLater(VeterancyBar.Update, 500)
    zo_callLater(VeterancyBar.Update, 1500)
end

local function OnRewardTrackProgress(_, trackType)
    if trackType == REWARD_TRACK_TYPE_AVA_VETERANCY then
        VeterancyBar.Update()
    end
end

local function OnLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    VeterancyBar.savedVars = ZO_SavedVars:NewAccountWide("VeterancyBarSavedVariables", 1, nil, VeterancyBar.defaults)

    VeterancyBar.CreateUI()
    VeterancyBar.Update()

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_REWARD_TRACK_PROGRESS_GAINED, OnRewardTrackProgress)

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, RefreshAfterActivation)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnLoaded)