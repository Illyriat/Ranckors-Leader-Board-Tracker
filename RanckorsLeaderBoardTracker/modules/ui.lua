local ADDON_TITLE = "Ranckors Leaderboard Tracker"
local ADDON_VERSION = "v1.0.1"
local ADDON_LINK = "https://illyriat.com"

RanckorsUI = {}

RanckorsUI.uiWindow = nil
RanckorsUI.uiContent = nil

function RanckorsUI.CreateUIWindow(savedVars)
    if RanckorsUI.uiWindow then
        d("UI window already exists.")
        return RanckorsUI.uiWindow, RanckorsUI.uiContent
    end

    d("Creating UI window...")

    local fixedWidth = 375
    local fixedHeight = 250

    RanckorsUI.uiWindow = WINDOW_MANAGER:CreateTopLevelWindow("RanckorsUIWindow")
    RanckorsUI.uiWindow:SetDimensions(fixedWidth, fixedHeight)
    RanckorsUI.uiWindow:SetMovable(true)
    RanckorsUI.uiWindow:SetMouseEnabled(true)
    RanckorsUI.uiWindow:SetClampedToScreen(true)
    RanckorsUI.uiWindow:SetHidden(false)

    local customBg = WINDOW_MANAGER:CreateControl("$(parent)CustomBackground", RanckorsUI.uiWindow, CT_TEXTURE)
    customBg:SetAnchorFill(RanckorsUI.uiWindow)
    customBg:SetTexture("EsoUI/Art/ChatWindow/chat_bg_center.dds")
    customBg:SetColor(0, 0, 0, 0.8)
    customBg:SetDrawLayer(DL_BACKGROUND)

    local titleLabel = WINDOW_MANAGER:CreateControl("$(parent)Title", RanckorsUI.uiWindow, CT_LABEL)
    titleLabel:SetFont("ZoFontGameLargeBold")
    titleLabel:SetText(ADDON_TITLE)
    titleLabel:SetAnchor(TOPLEFT, RanckorsUI.uiWindow, TOPLEFT, 10, 8)
    titleLabel:SetDimensions(260, 25)
    titleLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    titleLabel:SetMouseEnabled(true)
    titleLabel:SetHandler("OnMouseUp", function()
        RequestOpenUnsafeURL(ADDON_LINK)
    end)

    local versionLabel = WINDOW_MANAGER:CreateControl("$(parent)Version", RanckorsUI.uiWindow, CT_LABEL)
    versionLabel:SetFont("ZoFontGameSmall")
    versionLabel:SetText(ADDON_VERSION)
    versionLabel:SetAnchor(TOPRIGHT, RanckorsUI.uiWindow, TOPRIGHT, -10, 12)
    versionLabel:SetDimensions(60, 15)
    versionLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())

    RanckorsUI.uiContent = WINDOW_MANAGER:CreateControl("$(parent)Content", RanckorsUI.uiWindow, CT_LABEL)
    RanckorsUI.uiContent:SetAnchor(TOPLEFT, RanckorsUI.uiWindow, TOPLEFT, 5, 40)
    RanckorsUI.uiContent:SetAnchor(BOTTOMRIGHT, RanckorsUI.uiWindow, BOTTOMRIGHT, -5, -5)
    RanckorsUI.uiContent:SetWrapMode(TEXT_WRAP_MODE_NONE)
    RanckorsUI.uiContent:SetFont("ZoFontGameBold|14")

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
        local fixedWidth = 375
        local fixedHeight = 220

        RanckorsUI.uiWindow:ClearAnchors()
        RanckorsUI.uiWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, savedVars.window.x or 100, savedVars.window.y or 100)
        RanckorsUI.uiWindow:SetDimensions(fixedWidth, fixedHeight)
        RanckorsUI.uiWindow:SetHidden(false)
    end, 100)
end

local function OnSceneStateChange(oldState, newState)
    if newState == SCENE_SHOWING then
        RanckorsUI.uiWindow:SetHidden(false)
    elseif newState == SCENE_HIDDEN then
        RanckorsUI.uiWindow:SetHidden(true)
    end
end

function RanckorsUI.RegisterSceneManagement()
    SCENE_MANAGER:GetScene("hud"):RegisterCallback("StateChange", OnSceneStateChange)
    SCENE_MANAGER:GetScene("hudui"):RegisterCallback("StateChange", OnSceneStateChange)
end