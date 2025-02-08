-- -- ----------------------------------------------
-- -- Module to handle Cyrodiil campaign information
-- -- ----------------------------------------------


-- -- The following is an ingame debug script
-- -- /script for i=1,GetNumCampaignLeaderboardEntries(GetCurrentCampaignId()), 1 do d(GetCampaignLeaderboardEntryInfo(GetCurrentCampaignId(), i)) end

-------------------------------
-- Base Color Definitions (Magic Strings)
-------------------------------
local Colors = {
    Ebonheart  = "|cFF0000",   -- Red
    Aldmeri    = "|cFFFF00",   -- Yellow
    Daggerfall = "|c0000FF",   -- Blue
    Green      = "|c00FF00",   -- Green
    White      = "|cFFFFFF",   -- White
    Grey       = "|c808080",   -- Grey
    Error      = "|cFF0000",   -- Red for errors
    Reset      = "|r",         -- Reset color
    LightBlue  = "|c87CEEB",   -- Sky Blue
    DarkBlue   = "|c00008B",   -- Dark Blue
    LightGreen = "|c90EE90",   -- Light Green
    DarkGreen  = "|c006400",   -- Dark Green
    Orange     = "|cFFA500",   -- Orange
    Purple     = "|c800080",   -- Purple
    Magenta    = "|cFF00FF",   -- Magenta
    Cyan       = "|c00FFFF",   -- Cyan
    Pink       = "|cFFC0CB",   -- Pink
    Brown      = "|c8B4513",   -- Brown
    Gold       = "|cFFD700",   -- Gold
    Silver     = "|cC0C0C0",   -- Silver
    Maroon     = "|c800000",   -- Maroon
    Olive      = "|c808000",   -- Olive
    Teal       = "|c008080",   -- Teal
}

-------------------------------
-- Customizable Line Colors
-------------------------------
local LineColors = {
    HomeCampaign    = Colors.Grey,
    Alliance        = Colors.Grey,
    CurrentEmperor  = Colors.Green,
    EmperorReign    = Colors.Green,
    AldmeriPoints   = Colors.Aldmeri,
    EbonheartPoints = Colors.Ebonheart,
    DaggerfallPoints= Colors.Daggerfall,
    AllianceLeader  = Colors.White,
    Player          = Colors.White,
    PointDifference = Colors.Teal,
}

-------------------------------
-- Helper function to get default window settings
-------------------------------
local function GetDefaultWindow()
    local fallbackWidth = 1024
    local fallbackHeight = 768
    local screenWidth = (GuiRoot and GuiRoot:GetWidth()) or fallbackWidth
    local screenHeight = (GuiRoot and GuiRoot:GetHeight()) or fallbackHeight
    return {
        x = screenWidth - 420,
        y = screenHeight * 0.1,
        width = 600,  -- Increased width
        height = 400  -- Increased height
    }
end

-------------------------------
-- Define the addon namespace and defaults
-------------------------------
RanckorsLeaderBoardTracker = {}
RanckorsLeaderBoardTracker.defaults = {
    window = GetDefaultWindow()
}

-------------------------------
-- Initialize Saved Variables
-------------------------------
local function InitializeSavedVars()
    RanckorsLeaderBoardTracker.savedVars = ZO_SavedVars:New("RanckorsLeaderBoardTrackerSavedVariables", 1, nil, RanckorsLeaderBoardTracker.defaults)
    d(Colors.Green .. "SavedVariables initialized." .. Colors.Reset)
end

-------------------------------
-- Global variables for UI controls
-------------------------------
local uiWindow, uiContent

-------------------------------
-- Function to create the UI window
-------------------------------
local function CreateUIWindow()
    uiWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsUIWindow")
    local s = RanckorsLeaderBoardTracker.savedVars.window

    -- Increased window size for long text
    uiWindow:SetDimensions(600, 400)
    uiWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, s.x, s.y)
    uiWindow:SetHidden(false)
    uiWindow:SetMovable(true)
    uiWindow:SetMouseEnabled(true)
    uiWindow:SetClampedToScreen(true)

    -- Custom background setup
    local customBg = WINDOW_MANAGER:CreateControl("$(parent)CustomBackground", uiWindow, CT_TEXTURE)
    customBg:SetAnchorFill(uiWindow)
    customBg:SetTexture("EsoUI/Art/Miscellaneous/blank.dds")
    customBg:SetColor(0, 0, 0, 1)

    -- Content setup
    uiContent = WINDOW_MANAGER:CreateControl("$(parent)Content", uiWindow, CT_LABEL)
    local margin = 5
    uiContent:SetAnchor(TOPLEFT, uiWindow, TOPLEFT, margin, margin)
    uiContent:SetAnchor(BOTTOMRIGHT, uiWindow, BOTTOMRIGHT, -margin, -margin)
    uiContent:SetWrapMode(TEXT_WRAP_MODE_NONE)  -- No text wrapping
    uiContent:SetMaxLineCount(100)
    uiContent:SetFont("ZoFontGameBold|14")  -- Reduced font for better fit

    -- Save window position on move
    uiWindow:SetHandler("OnMoveStop", function()
        RanckorsLeaderBoardTracker.savedVars.window.x = uiWindow:GetLeft()
        RanckorsLeaderBoardTracker.savedVars.window.y = uiWindow:GetTop()
        d(Colors.Green .. "Window position saved: x=" .. uiWindow:GetLeft() .. ", y=" .. uiWindow:GetTop() .. Colors.Reset)
    end)

    -- Restore window position after UI creation
    zo_callLater(function()
        RestoreWindowPositionAndSize()
    end, 100)

    return uiWindow, uiContent
end

-------------------------------
-- Function to update the UI with new text
-------------------------------
local function UpdateUI(newText, clearBeforeUpdate)
    if clearBeforeUpdate then
        uiContent:SetText("")
    end

    -- Use single line breaks instead of double padding
    local paddedText = newText:gsub("\n\n", "\n")
    uiContent:SetText(paddedText)
end

-------------------------------
-- Function to restore window position and size
-------------------------------
local function RestoreWindowPositionAndSize()
    local savedWindow = RanckorsLeaderBoardTracker.savedVars.window
    if not savedWindow then return end

    uiWindow:ClearAnchors()
    uiWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, savedWindow.x, savedWindow.y)
    uiWindow:SetDimensions(600, 400)  -- Ensure it matches the new size
    uiContent:SetFont("ZoFontGameBold|14")

    d(Colors.Green .. "Window restored: x=" .. savedWindow.x .. ", y=" .. savedWindow.y .. Colors.Reset)
end

-------------------------------
-- Function to format time
-------------------------------
local function FormatReignDuration(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
    return string.format("%d days %02d:%02d:%02d", days, hours, minutes, remainingSeconds)
end

-------------------------------
-- Function to format numbers with commas
-------------------------------
local function FormatNumberWithCommas(number)
    local formatted = tostring(number)
    while true do
        formatted, count = formatted:gsub("^(%d+)(%d%d%d)", "%1,%2")
        if count == 0 then break end
    end
    return formatted
end

-------------------------------
-- Function to get alliance name
-------------------------------
local function GetAllianceName(allianceIndex)
    if allianceIndex == ALLIANCE_ALDMERI_DOMINION then
        return "Aldmeri Dominion"
    elseif allianceIndex == ALLIANCE_EBONHEART_PACT then
        return "Ebonheart Pact"
    elseif allianceIndex == ALLIANCE_DAGGERFALL_COVENANT then
        return "Daggerfall Covenant"
    else
        return "Unknown Alliance"
    end
end

-------------------------------
-- Function to get alliance color
-------------------------------
local function GetAllianceColor(allianceIndex)
    if allianceIndex == ALLIANCE_ALDMERI_DOMINION then
        return Colors.Aldmeri
    elseif allianceIndex == ALLIANCE_EBONHEART_PACT then
        return Colors.Ebonheart
    elseif allianceIndex == ALLIANCE_DAGGERFALL_COVENANT then
        return Colors.Daggerfall
    else
        return Colors.White
    end
end

-------------------------------
-- Calculate potential points
-------------------------------
function RanckorsLeaderBoardTracker:CalculatePotentialPoints(allianceIndex, campaignId)
    local currentPoints = 0
    local potentialPoints = 0

    if type(GetCampaignAllianceScore) == "function" then
        currentPoints = GetCampaignAllianceScore(campaignId, allianceIndex) or 0
    else
        d(Colors.Error .. "Error: GetCampaignAllianceScore is not available." .. Colors.Reset)
    end

    if type(GetCampaignAlliancePotentialScore) == "function" then
        potentialPoints = GetCampaignAlliancePotentialScore(campaignId, allianceIndex) or 0
    else
        d(Colors.Error .. "Error: GetCampaignAlliancePotentialScore is not available." .. Colors.Reset)
    end

    return potentialPoints
end

-------------------------------
-- Process leaderboard data
-------------------------------
local function ProcessLeaderboardData(campaignId, playerAlliance)
    local uiBuffer = {}
    local leaderName, leaderPoints
    local playerName = GetUnitName("player")
    local playerPosition, playerPoints

    local totalEntries = GetNumCampaignLeaderboardEntries(campaignId)

    for i = 1, totalEntries do
        local _, rank, charName, points, _, alliance = GetCampaignLeaderboardEntryInfo(campaignId, i)
        if alliance == playerAlliance then
            if not leaderName then
                leaderName = charName
                leaderPoints = points
            end
            if charName == playerName then
                playerPosition = rank
                playerPoints = points
            end
        end
    end

    if leaderName and playerPosition then
        local pointDifference = leaderPoints - playerPoints
        table.insert(uiBuffer, LineColors.AllianceLeader .. "Alliance Leader: " .. leaderName 
                     .. " (" .. FormatNumberWithCommas(leaderPoints) .. " points)" .. Colors.Reset)
        table.insert(uiBuffer, LineColors.Player .. "Player: " .. playerName 
                     .. " at Rank " .. playerPosition 
                     .. " (" .. FormatNumberWithCommas(playerPoints) .. " points)" .. Colors.Reset)
        table.insert(uiBuffer, LineColors.PointDifference .. "Point Difference: " 
                     .. FormatNumberWithCommas(pointDifference) .. Colors.Reset)
    else
        table.insert(uiBuffer, Colors.Error .. "Error: Leaderboard data unavailable or player not found." .. Colors.Reset)
    end

    return table.concat(uiBuffer, "\n")
end


-------------------------------
-- Refresh all data
-------------------------------
local function RefreshAllData()
    local uiBuffer = {}

    -- Get campaign and player details
    local homeCampaignId = GetAssignedCampaignId("player")
    local homeCampaignName = GetCampaignName(homeCampaignId) or "Unknown"
    local playerAlliance = GetUnitAlliance("player")
    local allianceName = GetAllianceName(playerAlliance) or "Unknown"

    -- Home Campaign and Alliance info
    table.insert(uiBuffer, LineColors.HomeCampaign .. "Home Campaign: " .. homeCampaignName .. Colors.Reset)
    table.insert(uiBuffer, LineColors.Alliance .. "Alliance: " .. allianceName .. Colors.Reset)

    -- Emperor details
    local emperorAlliance, emperorName = GetCampaignEmperorInfo(homeCampaignId)
    local emperorAllianceName = GetAllianceName(emperorAlliance) or "None"
    if emperorName and emperorName ~= "" then
        table.insert(uiBuffer, LineColors.CurrentEmperor .. "Current Emperor: " .. emperorName .. 
                     " (" .. emperorAllianceName .. ")" .. Colors.Reset)
        local reignDurationSeconds = GetCampaignEmperorReignDuration(homeCampaignId)
        if reignDurationSeconds and reignDurationSeconds > 0 then
            local formattedDuration = FormatReignDuration(reignDurationSeconds)
            table.insert(uiBuffer, LineColors.EmperorReign .. "Emperor Reign Duration: " .. formattedDuration .. Colors.Reset)
        else
            table.insert(uiBuffer, Colors.Error .. "Error: Reign duration data unavailable." .. Colors.Reset)
        end
    else
        table.insert(uiBuffer, Colors.Error .. "No Emperor currently assigned." .. Colors.Reset)
    end

    -- Alliance scores
    local alliances = {
        { index = ALLIANCE_ALDMERI_DOMINION, name = "Aldmeri", lineColor = LineColors.AldmeriPoints },
        { index = ALLIANCE_EBONHEART_PACT, name = "Ebonheart", lineColor = LineColors.EbonheartPoints },
        { index = ALLIANCE_DAGGERFALL_COVENANT, name = "Daggerfall", lineColor = LineColors.DaggerfallPoints }
    }
    for _, a in ipairs(alliances) do
        local currentPoints = GetCampaignAllianceScore(homeCampaignId, a.index) or 0
        local potentialPoints = RanckorsLeaderBoardTracker:CalculatePotentialPoints(a.index, homeCampaignId) or 0
        table.insert(uiBuffer, string.format("%s%s Points: %s, Potential: %s%s", a.lineColor, a.name, 
                                             FormatNumberWithCommas(currentPoints), FormatNumberWithCommas(potentialPoints), Colors.Reset))
    end

    -- Append leaderboard details
    local leaderboardDetails = ProcessLeaderboardData(homeCampaignId, playerAlliance)
    table.insert(uiBuffer, leaderboardDetails)

    -- Display the final text
    local finalText = table.concat(uiBuffer, "\n")
    UpdateUI(finalText, true)
end


-------------------------------
-- Fetch leaderboard data
-------------------------------
function RanckorsLeaderBoardTracker:FetchLeaderboardData()
    d(Colors.Green .. "Fetching Leaderboard Data..." .. Colors.Reset)

    local homeCampaignId = GetAssignedCampaignId("player")
    if homeCampaignId == 0 then
        UpdateUI(Colors.Error .. "Error: No home campaign assigned." .. Colors.Reset, true)
        return
    end

    QueryCampaignLeaderboardData(homeCampaignId)
    zo_callLater(function()
        RefreshAllData()
    end, 5000)
end

-------------------------------
-- Event handlers
-------------------------------
function RanckorsLeaderBoardTracker.OnPlayerActivated(event, initial)
    SCENE_MANAGER:Show(CAMPAIGN_OVERVIEW_SCENE:GetName())
    zo_callLater(function()
        SCENE_MANAGER:Hide(CAMPAIGN_OVERVIEW_SCENE:GetName())
        RanckorsLeaderBoardTracker:FetchLeaderboardData()
    end, 1000)
end

-------------------------------
-- Main initialization function
-------------------------------
function RanckorsLeaderBoardTracker:Initialize()
    uiWindow, uiContent = CreateUIWindow()

    EVENT_MANAGER:RegisterForEvent("RanckorsLeaderBoardTracker", EVENT_PLAYER_ACTIVATED, RanckorsLeaderBoardTracker.OnPlayerActivated)
end

-------------------------------
-- Add-on loaded event
-------------------------------
local function OnAddOnLoaded(event, addonName)
    if addonName ~= "RanckorsLeaderBoardTracker" then return end
    EVENT_MANAGER:UnregisterForEvent("RanckorsLeaderBoardTracker", EVENT_ADD_ON_LOADED)

    InitializeSavedVars()
    RanckorsLeaderBoardTracker:Initialize()
end

EVENT_MANAGER:RegisterForEvent("RanckorsLeaderBoardTracker", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
