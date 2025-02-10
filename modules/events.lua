RanckorsEvents = {}

function RanckorsEvents.OnAddOnLoaded(event, addonName)
    if addonName ~= "RanckorsLeaderBoardTracker" then return end

    d("Ranckors Leaderboard Tracker loaded successfully!")

    -- Example: Display leaderboard data after the addon is loaded
    local campaignId = GetAssignedCampaignId("player")
    local playerAlliance = GetUnitAlliance("player")

    if campaignId > 0 then
        local leaderboardData = RanckorsData.ProcessLeaderboardData(campaignId, playerAlliance)
        d("Displaying leaderboard data:\n" .. leaderboardData)
    else
        d(RanckorsColors.Error .. "No campaign assigned to the player." .. RanckorsColors.Reset)
    end
end

function RanckorsEvents.RegisterEvents()
    -- Future events can be registered here if needed
end
