-- Minimal UI mocks. Native key dispatch and client rendering require a real client.
return function(variant)
    local client = {}
    local modern = variant ~= "legacy"
    local frameMethods = {}
    local function noop() end

    function frameMethods:SetScript(script, handler)
        self.scripts[script] = handler
    end
    function frameMethods:HookScript(script, hook)
        local original = self.scripts[script] or noop
        self.scripts[script] = function(...)
            original(...)
            hook(...)
        end
    end
    function frameMethods:Fire(script, ...)
        local handler = self.scripts[script] or noop
        handler(self, ...)
    end
    function frameMethods:Hide()
        self.shown = false
        self:Fire("OnHide")
    end
    function frameMethods:Show()
        self.shown = true
    end
    function frameMethods:IsVisible()
        return self.shown
    end
    function frameMethods:EnableKeyboard(enabled)
        self.keyboard = enabled
    end
    function frameMethods:IsKeyboardEnabled()
        return self.keyboard
    end
    function frameMethods:SetFrameStrata(strata)
        if strata == "TOOLTIP" then
            client.capture = self
        end
    end
    function frameMethods:SetText(text)
        self.text = text
        if self.kind == "Button" then
            client.buttons[text] = self
        end
    end
    function frameMethods:CreateFontString()
        local line = setmetatable({}, { __index = frameMethods })
        self.labels[#self.labels + 1] = line
        return line
    end
    function frameMethods:SetupMenu(generator)
        self.generator = generator
    end
    function frameMethods:RegisterEvent(event)
        self.events[event] = true
    end
    function frameMethods:UnregisterEvent(event)
        self.events[event] = nil
    end
    frameMethods.SetPoint = noop
    frameMethods.SetSize = noop
    frameMethods.SetDefaultText = noop
    frameMethods.HasScript = function() return true end

    function client:OpenChat(box)
        self:CloseChat()
        if not box then
            box = CreateFrame("EditBox")
            box.text, box.cursor, box.writes = "", 0, 0
            box.HasFocus = function(self) return self.focused end
            box.GetText = function(self) return self.text end
            box.GetCursorPosition = function(self) return self.cursor end
            box.GetMaxBytes = function(self) return self.maxBytes end
            box.IsInIMECompositionMode = function(self) return self.composing end
            box.SetCursorPosition = function(self, cursor) self.cursor = cursor end
            box.ClearFocus = function() self:CloseChat() end
            if not modern then
                box:SetScript("OnTabPressed", function(editBox)
                    if not ChatEdit_CustomTabPressed() then
                        editBox.normalTabs = (editBox.normalTabs or 0) + 1
                    end
                end)
            end
            if modern then
                box.ExtractTellTarget = function(_, text, chatType)
                    local target, body = text:match("^%s*([^%s|\"]%S*)%s+(.*)$")
                    if chatType == "SMART_WHISPER" then
                        local fullName, rest = text:match("^(First Last)%s+(.*)$")
                        if fullName then
                            target, body = fullName, rest
                        elseif body == "привет" then
                            return false
                        end
                    end
                    return target ~= nil, target, chatType, body
                end
            end
            box.SetText = function(self, text)
                self.writes = self.writes + 1
                self.text = text
                self.cursor = #text
                if self.nativeParsing and text:sub(1, 3) == "/g " then
                    self.text, self.route = text:sub(4), "GUILD"
                end
            end
        end
        if ChatFrameUtil then
            ChatFrameUtil.ActivateChat(box)
        else
            ChatEdit_ActivateChat(box)
        end
        return box
    end

    function client:CloseChat()
        local box = self.active
        if box then
            self.active = nil
            box.focused = false
            box:Fire("OnEditFocusLost")
        end
    end

    function client:Key(frame, key)
        if not modern and frame.kind == "EditBox" and key == "TAB" and frame.focused and frame.shown then
            frame:Fire("OnTabPressed")
        elseif frame.keyboard then
            frame:Fire("OnKeyDown", key)
        end
    end

    function client:Shortcut(frame, key)
        local modifier = key:match("^(%u+)%-TAB$")
        if modifier then
            self.shift, self.control = modifier == "SHIFT", modifier == "CTRL"
            self:Key(frame, "TAB")
            self.shift, self.control = false, false
        else
            self:Key(frame, key)
        end
    end

    function client:OpenDropdown()
        self.options = {}
        local dropdown = self.dropdown
        if modern then
            dropdown.generator(dropdown, {
                CreateRadio = function(_, text, isSelected, select, id)
                    self.options[#self.options + 1] = {
                        text = text,
                        checked = isSelected(id),
                        pick = function() select(id) end,
                    }
                end,
            })
        else
            dropdown.generator()
        end
        return self.options
    end

    function client:Boot(saved, extraMapping)
        self:CloseChat()
        self.panel, self.capture, self.dropdown = nil, nil, nil
        self.buttons, self.options, self.modified = {}, {}, false
        local frames = {}
        function CreateFrame(kind, _, _, template)
            local frame = setmetatable({
                kind = kind, scripts = {}, labels = {}, events = {}, shown = true, keyboard = false,
            }, { __index = frameMethods })
            frames[#frames + 1] = frame
            if template == "UIDropDownMenuTemplate" or template == "WowStyle1DropdownTemplate" then
                self.dropdown = frame
            end
            return frame
        end
        function hooksecurefunc(target, key, hook)
            if type(target) == "string" then
                target, key, hook = _G, target, key
            end
            local original = target[key]
            target[key] = function(...)
                original(...)
                hook(...)
            end
        end
        function IsModifierKeyDown() return self.modified end
        function GetLocale() return self.locale or "enUS" end
        function IsShiftKeyDown() return self.shift end
        function IsControlKeyDown() return self.control end
        function IsAltKeyDown() return self.modified end
        function GetCurrentKeyBoardFocus() return self.active end
        function GetBindingAction(key) return key == "F3" and "TARGETPARTYMEMBER2" or "" end

        SLASH_GUILD1, SLASH_PARTY1, SLASH_RAID1, SLASH_SAY1 = "/g", "/p", "/raid", "/s"
        SLASH_WHISPER1, SLASH_WHISPER2, SLASH_WHISPER3 = "/w", "/tell", "/ш"
        SLASH_SMART_WHISPER1 = modern and "/smartw" or nil
        SLASH_CHANNEL1, SLASH_REPLY1 = "/c", "/r"
        Settings, MenuUtil, ChatFrameUtil = nil, nil, nil
        ChatEdit_GetActiveWindow, ChatEdit_ActivateChat, InterfaceOptions_AddCategory = nil, nil, nil
        ChatEdit_CustomTabPressed = nil
        UIDropDownMenu_SetWidth, UIDropDownMenu_SetSelectedValue = nil, nil
        UIDropDownMenu_Initialize, UIDropDownMenu_CreateInfo, UIDropDownMenu_AddButton = nil, nil, nil
        local function active() return self.active end
        local function activate(box)
            self.active, box.focused = box, true
        end
        if modern then
            ChatFrameUtil = { GetActiveWindow = active, ActivateChat = activate }
            Settings = {
                RegisterCanvasLayoutCategory = function(panel, name) return { panel = panel, name = name } end,
                RegisterAddOnCategory = function(category) self.panel = category.panel end,
            }
            MenuUtil = { CreateContextMenu = noop }
        else
            ChatEdit_GetActiveWindow, ChatEdit_ActivateChat = active, activate
            ChatEdit_CustomTabPressed = function() return self.tabHandled end
            InterfaceOptions_AddCategory = function(panel) self.panel = panel end
            UIDropDownMenu_SetWidth = noop
            UIDropDownMenu_SetSelectedValue = function(dropdown, value) dropdown.value = value end
            UIDropDownMenu_Initialize = function(dropdown, generator) dropdown.generator = generator end
            UIDropDownMenu_CreateInfo = function() return {} end
            UIDropDownMenu_AddButton = function(item)
                self.options[#self.options + 1] = {
                    text = item.text, pick = function() item.func(item) end,
                }
            end
        end

        LayoutFixDB = saved
        local suffix = ({ legacy = "", modern = "_Mainline", era = "_Vanilla" })[variant]
        local toc = assert(io.open("LayoutFix/LayoutFix" .. suffix .. ".toc"))
        local manifest = toc:read("*a")
        toc:close()
        assert(manifest:match("## SavedVariables: LayoutFixDB"))
        local interface = ({ legacy = "30300", modern = "120105", era = "11509" })[variant]
        assert(manifest:match("## Interface: " .. interface .. "[\r\n]"))
        local xml = assert(io.open("LayoutFix/" .. assert(manifest:match("\n([^#\r\n][^\r\n]*%.xml)"))))
        local addon = {}
        for path in xml:read("*a"):gmatch('<Script file="([^"]+)"') do
            assert(loadfile("LayoutFix/" .. path:gsub("\\", "/")))("LayoutFix", addon)
        end
        xml:close()
        if extraMapping then
            assert(addon:RegisterMapping(extraMapping))
        end
        for _, frame in ipairs(frames) do
            if frame.events.ADDON_LOADED then
                frame:Fire("OnEvent", "ADDON_LOADED", "Blizzard_Other")
                assert(frame.events.ADDON_LOADED)
                frame:Fire("OnEvent", "ADDON_LOADED", "LayoutFix")
                assert(not frame.events.ADDON_LOADED)
            end
        end
        return addon
    end
    return client
end
