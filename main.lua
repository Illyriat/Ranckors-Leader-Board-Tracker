RanckorsLeaderBoardTracker = {}  -- Define the global table
d("Ranckors Leaderboard Tracker is initializing...")

function RanckorsLeaderBoardTracker.InitializeUI()
    d("RanckorsLeaderBoardTracker.InitializeUI() called.")

    -- Create the UI window and restore its position
    RanckorsUI.CreateUIWindow(RanckorsLeaderBoardTracker.savedVars)
    RanckorsUI.RestoreWindowPositionAndSize(RanckorsLeaderBoardTracker.savedVars)

    -- Register scene management to show/hide the UI
    RanckorsUI.RegisterSceneManagement()

    -- Fetch and display the leaderboard data
    local leaderboardData = RanckorsData.RefreshAllData()

    -- Set the UI content
    if RanckorsUI.uiContent then
        RanckorsUI.uiContent:SetText(leaderboardData)
        d("Leaderboard data set on the UI.")
    end
end

EVENT_MANAGER:RegisterForEvent("RanckorsLeaderBoardTracker", EVENT_ADD_ON_LOADED, function(event, addonName)
    if addonName == "RanckorsLeaderBoardTracker" then
        d("Correct addon loaded: RanckorsLeaderBoardTracker.")

        -- Initialize saved variables
        RanckorsSavedVars.Initialize()

        -- Initialize the UI
        RanckorsLeaderBoardTracker.InitializeUI()
    end
end)

local function UpdateLeaderboardData()
    local updatedData = RanckorsData.RefreshAllData()
    if RanckorsUI.uiContent then
        RanckorsUI.uiContent:SetText(updatedData)
    end
end

-- Refresh the leaderboard data every 10 seconds
zo_callLater(function()
    EVENT_MANAGER:RegisterForUpdate("RanckorsLeaderBoardUpdate", 10000, UpdateLeaderboardData)
end, 5000)  -- Delay initial update

function RanckorsLeaderBoardTracker:CalculatePotentialPoints(allianceIndex, campaignId)
    local potentialPoints = 0
    if type(GetCampaignAlliancePotentialScore) == "function" then
        potentialPoints = GetCampaignAlliancePotentialScore(campaignId, allianceIndex) or 0
    else
        d("|cFF0000Error: GetCampaignAlliancePotentialScore is not available.|r")
    end
    return potentialPoints
end
