RanckorsSavedVars = {}

function RanckorsSavedVars.Initialize()
    RanckorsLeaderBoardTracker.savedVars = ZO_SavedVars:New("RanckorsLeaderBoardTrackerSavedVariables", 1, nil, {
        window = {
            x = 100,
            y = 100,
            width = 600,
            height = 400
        }
    })

    d("|c00FF00Saved variables initialized.|r")
end
