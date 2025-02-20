RanckorsUI = {}

RanckorsUI.uiWindow = nil
RanckorsUI.uiContent = nil

function RanckorsUI.CreateUIWindow(savedVars)
    if RanckorsUI.uiWindow then
        d("UI window already exists.")
        return RanckorsUI.uiWindow, RanckorsUI.uiContent
    end

    d("Creating UI window...")

    -- Force a fixed size and ignore savedVars
    local fixedWidth = 375
    local fixedHeight = 195

    -- Create the main UI window
    RanckorsUI.uiWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsUIWindow")
    RanckorsUI.uiWindow:SetDimensions(fixedWidth, fixedHeight)  -- ⬅ Forces a fixed size
    RanckorsUI.uiWindow:SetMovable(true)
    RanckorsUI.uiWindow:SetMouseEnabled(true)
    RanckorsUI.uiWindow:SetClampedToScreen(true)
    RanckorsUI.uiWindow:SetHidden(false)

    -- Create a background using CT_TEXTURE (since CT_BACKDROP does not exist)
    local customBg = WINDOW_MANAGER:CreateControl("$(parent)CustomBackground", RanckorsUI.uiWindow, CT_TEXTURE)
    customBg:SetAnchorFill(RanckorsUI.uiWindow) -- Fill entire window
    customBg:SetTexture("EsoUI/Art/ChatWindow/chat_bg_center.dds") -- Use a blank texture
    customBg:SetColor(0, 0, 0, 0.8) -- Black with 60% transparency
    customBg:SetDrawLayer(DL_BACKGROUND) -- Ensure it's drawn behind everything


    -- Content setup
    RanckorsUI.uiContent = WINDOW_MANAGER:CreateControl("$(parent)Content", RanckorsUI.uiWindow, CT_LABEL)
    RanckorsUI.uiContent:SetAnchor(TOPLEFT, RanckorsUI.uiWindow, TOPLEFT, 5, 5)
    RanckorsUI.uiContent:SetAnchor(BOTTOMRIGHT, RanckorsUI.uiWindow, BOTTOMRIGHT, -5, -5)
    RanckorsUI.uiContent:SetWrapMode(TEXT_WRAP_MODE_NONE)
    RanckorsUI.uiContent:SetFont("ZoFontGameBold|14")

    -- Disable resizing
    RanckorsUI.uiWindow:SetResizeHandleSize(0)

    d("UI window created successfully.")
    return RanckorsUI.uiWindow, RanckorsUI.uiContent
end


function RanckorsUI.RestoreWindowPositionAndSize(savedVars)
    if not RanckorsUI.uiWindow then
        d("UI window is nil. Creating it now.")
        RanckorsUI.CreateUIWindow(savedVars)
    end

    zo_callLater(function()
        local fixedWidth = 375  -- ⬅ Force width
        local fixedHeight = 195 -- ⬅ Force height

        RanckorsUI.uiWindow:ClearAnchors()
        RanckorsUI.uiWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, savedVars.window.x or 100, savedVars.window.y or 100)
        RanckorsUI.uiWindow:SetDimensions(fixedWidth, fixedHeight) -- ⬅ Force the same fixed size again
        RanckorsUI.uiWindow:SetHidden(false)
    end, 100)  -- Small delay to ensure UI is ready
end


-- Scene management for showing/hiding the UI
local function OnSceneStateChange(oldState, newState)
    if newState == SCENE_SHOWING then
        -- d("Showing UI window...")
        RanckorsUI.uiWindow:SetHidden(false)
    elseif newState == SCENE_HIDDEN then
        -- d("Hiding UI window...")
        RanckorsUI.uiWindow:SetHidden(true)
    end
end

function RanckorsUI.RegisterSceneManagement()
    SCENE_MANAGER:GetScene("hud"):RegisterCallback("StateChange", OnSceneStateChange)
    SCENE_MANAGER:GetScene("hudui"):RegisterCallback("StateChange", OnSceneStateChange)
end
