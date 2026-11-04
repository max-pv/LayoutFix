local addonName, LayoutFix = ...
local L = LayoutFix.L

local function label(panel, text, y, font)
    local line = panel:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
    line:SetPoint("TOPLEFT", 16, y)
    line:SetText(text)
    return line
end

local function button(panel, text, x, y, width, onClick)
    local control = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    control:SetPoint("TOPLEFT", x, y)
    control:SetSize(width, 24)
    control:SetText(text)
    control:SetScript("OnClick", onClick)
    return control
end

local function createMappingDropdown(panel, preferences)
    if MenuUtil and MenuUtil.CreateContextMenu then
        local dropdown = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
        dropdown:SetPoint("TOPLEFT", 16, -205)
        dropdown:SetSize(320, 26)
        dropdown:SetDefaultText(L.noMapping)
        dropdown:SetupMenu(function(_, root)
            for _, mapping in ipairs(LayoutFix:ListMappings()) do
                root:CreateRadio(L["mapping." .. mapping.id] or mapping.name, function(id)
                    return preferences.mapping == id
                end, function(id)
                    LayoutFix:SelectMapping(preferences, id)
                end, mapping.id)
            end
        end)
        return
    end

    local dropdown = CreateFrame("Frame", "LayoutFixMappingDropdown", panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 0, -205)
    UIDropDownMenu_SetWidth(dropdown, 300)
    UIDropDownMenu_Initialize(dropdown, function()
        for _, mapping in ipairs(LayoutFix:ListMappings()) do
            local item = UIDropDownMenu_CreateInfo()
            item.text, item.value = L["mapping." .. mapping.id] or mapping.name, mapping.id
            item.func = function(self)
                LayoutFix:SelectMapping(preferences, self.value)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
            end
            UIDropDownMenu_AddButton(item)
        end
    end)
    UIDropDownMenu_SetSelectedValue(dropdown, preferences.mapping)
end

local function createPanel(preferences)
    local modern = Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory
    if not modern and not InterfaceOptions_AddCategory then
        return
    end
    local panel = CreateFrame("Frame")
    panel:Hide()
    panel.name = addonName
    label(panel, "LayoutFix", -16, "GameFontNormalLarge")
    label(panel, L.description, -44, "GameFontHighlight")
    local shortcut = label(panel, "", -79)
    local status = label(panel, "", -130, "GameFontHighlight")
    local warning = label(panel, "", -153, "GameFontHighlight")
    local usesTab = LayoutFix.usesTabShortcut
    local keyHint = usesTab and L.pickTab or L.pickFunction
    local shortcutNames = { ["SHIFT-TAB"] = L.shiftTab, ["CTRL-TAB"] = L.controlTab }

    local function refreshShortcut()
        shortcut:SetText(L.currentShortcut:format(shortcutNames[preferences.shortcut] or preferences.shortcut))
        local action = not usesTab and GetBindingAction and GetBindingAction(preferences.shortcut, true)
        warning:SetText(action and action ~= "" and L.bindingWarning or "")
    end

    local capture = CreateFrame("Frame", nil, panel)
    capture:SetFrameStrata("TOOLTIP")
    capture:Hide()
    capture:SetScript("OnHide", function(self)
        self:EnableKeyboard(false)
    end)
    capture:SetScript("OnKeyDown", function(self, key)
        local shortcutKey
        if usesTab then
            shortcutKey = key == "TAB" and LayoutFix:GetTabShortcut()
        elseif not IsModifierKeyDown() then
            shortcutKey = key
        end
        if key == "ESCAPE" then
            status:SetText(L.canceled)
        elseif not shortcutKey or not LayoutFix:SelectShortcut(preferences, shortcutKey, usesTab) then
            status:SetText(keyHint)
            return
        else
            status:SetText(L.saved)
            refreshShortcut()
        end
        self:Hide()
    end)
    button(panel, L.assignKey, 16, -100, 140, function()
        local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
        if focus then
            focus:ClearFocus()
        end
        status:SetText(keyHint)
        capture:Show()
        capture:EnableKeyboard(true)
    end)
    button(panel, L.resetShortcut, 164, -100, 155, function()
        capture:Hide()
        LayoutFix:SelectShortcut(preferences, nil, usesTab)
        status:SetText(L.restored)
        refreshShortcut()
    end)
    panel:SetScript("OnShow", function()
        status:SetText("")
        refreshShortcut()
    end)
    panel:SetScript("OnHide", function()
        capture:Hide()
    end)

    label(panel, L.mapping, -185)
    createMappingDropdown(panel, preferences)
    refreshShortcut()
    if modern then
        local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        LayoutFixDB = LayoutFix:LoadPreferences(LayoutFixDB, LayoutFix.usesTabShortcut)
        LayoutFix.preferences = LayoutFixDB
        createPanel(LayoutFixDB)
        LayoutFix:InstallChatHook()
    end
end)
