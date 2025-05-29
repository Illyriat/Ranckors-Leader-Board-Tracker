RanckorsSavedVars = {}

function RanckorsSavedVars.Initialize()
    RanckorsLeaderBoardTracker.savedVars = ZO_SavedVars:New("RanckorsLeaderBoardTrackerSavedVariables", 1, nil, {
        window = {
            x = 100,
            y = 100
        }
    })

    d("|c00FF00Saved variables initialized.|r")
end
