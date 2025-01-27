-- -- ----------------------------------------------
-- -- Module to handle Cyrodiil campaign information
-- -- ----------------------------------------------


-- -- The following is an ingame debug script
-- -- /script for i=1,GetNumCampaignLeaderboardEntries(GetCurrentCampaignId()), 1 do d(GetCampaignLeaderboardEntryInfo(GetCurrentCampaignId(), i)) end



-- -- Add a table to hold the addon
RanckorsLeaderBoardTracker = {}

local function OnAddOnLoaded(event, addonName)
    if addonName ~= "RanckorsLeaderBoardTracker" then return end
    EVENT_MANAGER:UnregisterForEvent("RanckorsLeaderBoardTracker", EVENT_ADD_ON_LOADED)
    RanckorsLeaderBoardTracker:Initialize()
end

function RanckorsLeaderBoardTracker:Initialize()
    EVENT_MANAGER:RegisterForEvent("RanckorsLeaderBoardTracker", EVENT_PLAYER_ACTIVATED, RanckorsLeaderBoardTracker.OnPlayerActivated)
    d("|c00FF00RanckorsLeaderBoardTracker Initialized|r")

    CAMPAIGN_OVERVIEW_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            d("|c00FF00Campaign Overview Scene Showing|r")
            zo_callLater(function() RanckorsLeaderBoardTracker:SelectAssignedCampaignRulesetNode() end, 1000)
        elseif newState == SCENE_HIDDEN then
            d("|c00FF00Campaign Overview Scene Hidden|r")
            zo_callLater(function() RanckorsLeaderBoardTracker:FetchLeaderboardData() end, 2000)
        end
    end)
end

function RanckorsLeaderBoardTracker.OnPlayerActivated(event, initial)
    d("|c00FF00Player Activated Event Triggered|r")
    
    -- Show the Campaign Overview Scene
    SCENE_MANAGER:Show(CAMPAIGN_OVERVIEW_SCENE:GetName())
    
    -- Close the scene after a brief delay
    zo_callLater(function()
        SCENE_MANAGER:Hide(CAMPAIGN_OVERVIEW_SCENE:GetName())
    end, 500)  -- Adjust the delay as needed (500ms = half a second)
end


function RanckorsLeaderBoardTracker:SelectAssignedCampaignRulesetNode()
    local campaignId = GetAssignedCampaignId("player")
    if campaignId == 0 then
        d("|cFF0000Error: No assigned campaign.|r")
        return
    end
    local campaignName = GetCampaignName(campaignId) or "Unknown Campaign"
    d("|c00FF00Assigned Campaign: " .. campaignName .. "|r")
end

local function FormatReignDuration(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    seconds = seconds % 60
    return string.format("%d days %02d:%02d:%02d", days, hours, minutes, seconds)
end

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

function RanckorsLeaderBoardTracker:FetchLeaderboardData()
    d("|c00FF00FetchLeaderboardData Called|r")

    local homeCampaignId = GetAssignedCampaignId("player")
    if homeCampaignId == 0 then
        d("|cFF0000Error: No home campaign assigned.|r")
        return
    end

    local homeCampaignName = GetCampaignName(homeCampaignId)
    local playerAlliance = GetUnitAlliance("player")
    local allianceName = GetAllianceName(playerAlliance)

    if not homeCampaignName or not playerAlliance then
        d("|cFF0000Error: Missing campaign or alliance data.|r")
        return
    end

    d("|c00FF00Home Campaign: " .. homeCampaignName .. ", Alliance: " .. allianceName .. "|r")

    -- Fetch Emperor Info
    local emperorAlliance, emperorName = GetCampaignEmperorInfo(homeCampaignId)
    local emperorAllianceName = GetAllianceName(emperorAlliance)

    if emperorName and emperorName ~= "" then
        d("|c00FF00Current Emperor: " .. emperorName .. " (" .. emperorAllianceName .. ")|r")

        -- Fetch the correct reign duration
        local reignDurationSeconds = GetCampaignEmperorReignDuration(homeCampaignId)

        -- Ensure reignDurationSeconds is valid
        if reignDurationSeconds and reignDurationSeconds > 0 then
            local formattedDuration = FormatReignDuration(reignDurationSeconds)
            d("|c00FF00Emperor Reign Duration: " .. formattedDuration .. "|r")
        else
            d("|cFF0000Error: Reign duration data unavailable.|r")
        end
    else
        d("|cFF0000No Emperor currently assigned.|r")
    end

    -- Fetch and display the current points and potential points for all alliances
    for allianceIndex = ALLIANCE_ALDMERI_DOMINION, ALLIANCE_DAGGERFALL_COVENANT do
        local currentPoints, potentialPoints
        local allianceName = GetAllianceName(allianceIndex)

        -- Attempt to fetch current points
        local success, err = pcall(function()
            currentPoints = GetCampaignAllianceScore(homeCampaignId, allianceIndex)
        end)

        if not success or not currentPoints then
            d("|cFF0000Error: Unable to retrieve points for " .. allianceName .. ".|r")
            currentPoints = 0
        end

        -- Attempt to calculate potential points
        success, err = pcall(function()
            potentialPoints = self:CalculatePotentialPoints(allianceIndex, homeCampaignId)
        end)

        if not success or not potentialPoints then
            d("|cFF0000Error: Unable to calculate potential points for " .. allianceName .. ".|r")
            potentialPoints = 0
        end

        -- d("|c00FF00" .. allianceName .. " Points: " .. currentPoints .. "|r")
        -- d("|c00FF00" .. allianceName .. " Estimated Potential Points: " .. potentialPoints .. "|r")
    end

    -- Query the leaderboard
    QueryCampaignLeaderboardData(homeCampaignId)
    d("|c00FF00Querying Leaderboard Data...|r")

    -- Wait for leaderboard data to load and then process it
    zo_callLater(function()
        RanckorsLeaderBoardTracker:ProcessLeaderboardData(homeCampaignId, playerAlliance)
    end, 5000)
end


-- Helper function to add commas to numbers
    local function FormatNumberWithCommas(number)
        local formatted = tostring(number)
        while true do
            formatted, count = formatted:gsub("^(%d+)(%d%d%d)", "%1,%2")
            if count == 0 then break end
        end
        return formatted
    end

-- Helper function to calculate potential points
function RanckorsLeaderBoardTracker:CalculatePotentialPoints(allianceIndex, campaignId)
    -- Fetch current points
    local currentPoints = GetCampaignAllianceScore(campaignId, allianceIndex)
    if not currentPoints then
        d("|cFF0000Error: Unable to fetch current points for Alliance " .. allianceIndex .. ".|r")
        currentPoints = 0
    end

    -- Fetch potential score
    local potentialPoints = GetCampaignAlliancePotentialScore(campaignId, allianceIndex)
    if not potentialPoints then
        d("|cFF0000Error: Unable to fetch potential score for Alliance " .. allianceIndex .. ".|r")
        potentialPoints = 0
    end

    -- Combine both scores into a single string and display it
    local allianceName = GetAllianceName(allianceIndex)
    d("|c00FF00" .. allianceName .. ": " .. FormatNumberWithCommas(currentPoints) .. 
      " Points, " .. FormatNumberWithCommas(potentialPoints) .. " Potential Points|r")

    -- Return potential points as needed
    return potentialPoints
end


function RanckorsLeaderBoardTracker:ProcessLeaderboardData(campaignId, allianceIndex)
    local totalEntries = GetNumCampaignLeaderboardEntries(campaignId)
    d("|c00FF00Processing " .. totalEntries .. " Leaderboard Entries|r")

    local playerName = GetUnitName("player")
    local playerDisplayName = GetDisplayName()
    if not playerName or not playerDisplayName then
        d("|cFF0000Error: Unable to retrieve player info.|r")
        return
    end

    local leaderName, leaderPoints
    local playerPosition, playerPoints

    for i = 1, totalEntries do
        local _, rank, charName, points, _, alliance, displayName = GetCampaignLeaderboardEntryInfo(campaignId, i)
        if alliance == allianceIndex then
            leaderName = leaderName or charName
            leaderPoints = leaderPoints or points
            if charName == playerName or displayName == playerDisplayName then
                playerPosition = rank
                playerPoints = points
                break
            end
        end
    end

    if not leaderName then
        d("|cFF0000Error: Unable to find alliance leader.|r")
    elseif not playerPosition then
        d("|cFF0000Error: Player not found on leaderboard.|r")
    else
        d("|c00FF00Leader: " .. leaderName .. " (" .. FormatNumberWithCommas(leaderPoints) .. " points)|r")
        d("|c00FF00Player: " .. playerName .. " at rank " .. playerPosition .. " (" .. FormatNumberWithCommas(playerPoints) .. " points)|r")
        d("|c00FF00Point Difference: " .. FormatNumberWithCommas(leaderPoints - playerPoints) .. "|r")
    end
end
    

EVENT_MANAGER:RegisterForEvent("RanckorsLeaderBoardTracker", EVENT_ADD_ON_LOADED, OnAddOnLoaded)