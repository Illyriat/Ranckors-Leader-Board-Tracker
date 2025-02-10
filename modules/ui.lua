RanckorsUI = {}

RanckorsUI.uiWindow = nil
RanckorsUI.uiContent = nil

function RanckorsUI.CreateUIWindow(savedVars)
    if RanckorsUI.uiWindow then
        d("UI window already exists.")
        return RanckorsUI.uiWindow, RanckorsUI.uiContent
    end

    d("Creating UI window...")

    savedVars.window = savedVars.window or { x = 100, y = 100, width = 600, height = 400 }

    -- Create the main UI window
    RanckorsUI.uiWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsUIWindow")
    RanckorsUI.uiWindow:SetDimensions(savedVars.window.width, savedVars.window.height)
    RanckorsUI.uiWindow:SetMovable(true)
    RanckorsUI.uiWindow:SetMouseEnabled(true)
    RanckorsUI.uiWindow:SetClampedToScreen(true)
    RanckorsUI.uiWindow:SetHidden(false)

    -- Custom background
    local customBg = WINDOW_MANAGER:CreateControl("$(parent)CustomBackground", RanckorsUI.uiWindow, CT_TEXTURE)
    customBg:SetAnchorFill(RanckorsUI.uiWindow)
    customBg:SetTexture("EsoUI/Art/Miscellaneous/blank.dds")
    customBg:SetColor(0, 0, 0, 1)

    -- Content setup
    RanckorsUI.uiContent = WINDOW_MANAGER:CreateControl("$(parent)Content", RanckorsUI.uiWindow, CT_LABEL)
    RanckorsUI.uiContent:SetAnchor(TOPLEFT, RanckorsUI.uiWindow, TOPLEFT, 5, 5)
    RanckorsUI.uiContent:SetAnchor(BOTTOMRIGHT, RanckorsUI.uiWindow, BOTTOMRIGHT, -5, -5)
    RanckorsUI.uiContent:SetWrapMode(TEXT_WRAP_MODE_NONE)
    RanckorsUI.uiContent:SetFont("ZoFontGameBold|14")

    -- Save window position on movement
    RanckorsUI.uiWindow:SetHandler("OnMoveStop", function()
        local x, y = RanckorsUI.uiWindow:GetLeft(), RanckorsUI.uiWindow:GetTop()
        savedVars.window.x = x
        savedVars.window.y = y
        d("Window moved to: (" .. x .. ", " .. y .. "). Position saved.")
    end)

    d("UI window created successfully.")
    return RanckorsUI.uiWindow, RanckorsUI.uiContent
end

function RanckorsUI.RestoreWindowPositionAndSize(savedVars)
    savedVars.window = savedVars.window or { x = 100, y = 100, width = 600, height = 400 }

    if not RanckorsUI.uiWindow then
        d("UI window is nil. Creating it now.")
        RanckorsUI.CreateUIWindow(savedVars)
    end

    zo_callLater(function()
        local windowSettings = savedVars.window

        d("Restoring window position: (" .. windowSettings.x .. ", " .. windowSettings.y .. ").")
        RanckorsUI.uiWindow:ClearAnchors()
        RanckorsUI.uiWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, windowSettings.x or 100, windowSettings.y or 100)
        RanckorsUI.uiWindow:SetDimensions(windowSettings.width, windowSettings.height)
        RanckorsUI.uiWindow:SetHidden(false)
    end, 100)  -- Small delay to ensure UI is ready
end

-- Scene management for showing/hiding the UI
local function OnSceneStateChange(oldState, newState)
    if newState == SCENE_SHOWING then
        d("Showing UI window...")
        RanckorsUI.uiWindow:SetHidden(false)
    elseif newState == SCENE_HIDDEN then
        d("Hiding UI window...")
        RanckorsUI.uiWindow:SetHidden(true)
    end
end

function RanckorsUI.RegisterSceneManagement()
    SCENE_MANAGER:GetScene("hud"):RegisterCallback("StateChange", OnSceneStateChange)
    SCENE_MANAGER:GetScene("hudui"):RegisterCallback("StateChange", OnSceneStateChange)
end
