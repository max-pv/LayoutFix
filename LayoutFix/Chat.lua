local _, LayoutFix = ...
local hooked = {}
LayoutFix.usesTabShortcut = not (ChatFrameUtil and ChatFrameUtil.ActivateChat)
    and type(ChatEdit_CustomTabPressed) == "function"

-- These Blizzard slash types carry a message. Other commands are left intact.
local messageTypes = {
    "SAY", "YELL", "GUILD", "OFFICER", "PARTY", "RAID", "RAID_WARNING",
    "BATTLEGROUND", "INSTANCE_CHAT", "REPLY", "WHISPER", "SMART_WHISPER", "CHANNEL",
}
local slashTypes = {}
for _, chatType in ipairs(messageTypes) do
    local index = 1
    while _G["SLASH_" .. chatType .. index] do
        local alias = _G["SLASH_" .. chatType .. index]
        slashTypes[alias:upper()] = chatType
        index = index + 1
    end
end

local function activeChat()
    if ChatFrameUtil and ChatFrameUtil.GetActiveWindow then
        return ChatFrameUtil.GetActiveWindow()
    end
    if ChatEdit_GetActiveWindow then
        return ChatEdit_GetActiveWindow()
    end
end

local function messageStart(editBox, text)
    -- Parsed routing is already held by the EditBox. Only inspect a literal
    -- slash prefix when one is still present in the draft.
    if not text:match("^%s*/") then
        return 1
    end
    local command, start = text:match("^(/%S+)%s+()")
    if not command then
        return nil
    end
    local chatType = slashTypes[command:upper()]
    if chatType == "WHISPER" or chatType == "SMART_WHISPER" then
        if editBox.ExtractTellTarget then
            -- The modern parser can identify multiword targets without editing the draft.
            local found, target, _, body = editBox:ExtractTellTarget(text:sub(#command + 2), chatType)
            if found and body ~= "" and text:sub(-#body) == body then
                return #text - #body + 1, target
            end
            return nil
        end
        if chatType == "SMART_WHISPER" then
            return nil
        end
    end
    if chatType == "WHISPER" or chatType == "CHANNEL" then
        -- Normal character names (including Name-Realm) and channel names
        -- occupy one token. Leave link-based and quoted targets to Blizzard.
        return text:match('^[^%s|"]%S*%s+()', start)
    end
    if chatType or command:match("^/[1-9]%d*$") then
        return start
    end
end

local function hasChatMarkup(text)
    -- Also catches the opening codes for links, textures and colored text.
    return text:find("|[|HhCcRrTtAaKkn]", 1) ~= nil
end

local function convertChat(editBox)
    if editBox.IsInIMECompositionMode and editBox:IsInIMECompositionMode() then
        return
    end
    local text = editBox:GetText()
    if (issecretvalue and issecretvalue(text)) or not text or text == "" or hasChatMarkup(text) then
        return
    end
    local start, target = messageStart(editBox, text)
    if not start then
        return
    end
    local prefix, message = text:sub(1, start - 1), text:sub(start)
    if message:match("^%s*/") then
        return
    end

    local cursor = editBox.GetCursorPosition and editBox:GetCursorPosition()
    local messageCursor = cursor and math.max(0, cursor - #prefix)
    local converted, newCursor = LayoutFix:Convert(LayoutFix.preferences.mapping, message, nil, messageCursor)
    if converted == message or converted:match("^%s*/") or hasChatMarkup(converted) then
        return
    end
    local replacement = prefix .. converted
    if target then
        local newStart, newTarget = messageStart(editBox, replacement)
        if newStart ~= start or newTarget ~= target then
            return
        end
    end
    local maxBytes = editBox.GetMaxBytes and editBox:GetMaxBytes()
    if maxBytes and maxBytes > 0 and #replacement > maxBytes then
        return
    end

    editBox:SetText(replacement)
    if cursor and editBox.SetCursorPosition and editBox:HasFocus() then
        local actual = editBox:GetText()
        if issecretvalue and issecretvalue(actual) then
            return true
        end
        if actual == replacement then
            editBox:SetCursorPosition(cursor < #prefix and cursor or #prefix + newCursor)
        elseif prefix ~= "" and actual == converted then
            -- SetText may trigger Blizzard's own parser and remove the prefix.
            editBox:SetCursorPosition(newCursor)
        end
    end
    return true
end

local function isFocusedChat(editBox)
    return editBox and editBox:HasFocus() and editBox:IsVisible()
end

function LayoutFix:GetTabShortcut()
    if not IsAltKeyDown() then
        local shift, control = IsShiftKeyDown(), IsControlKeyDown()
        if shift and not control then
            return "SHIFT-TAB"
        elseif control and not shift then
            return "CTRL-TAB"
        end
    end
end

local function onKeyDown(editBox, key)
    if key == LayoutFix.preferences.shortcut and editBox == activeChat()
        and isFocusedChat(editBox) and not IsModifierKeyDown() then
        convertChat(editBox)
    end
end

local function restoreKeyboard(editBox)
    if hooked[editBox] then
        hooked[editBox] = false
        editBox:EnableKeyboard(false)
    end
end

local function hookChat(editBox)
    if not editBox or not editBox:HasFocus() then
        return
    end
    if hooked[editBox] == nil then
        if not editBox:HasScript("OnKeyDown") then
            return
        end
        editBox:HookScript("OnKeyDown", onKeyDown)
        editBox:HookScript("OnEditFocusLost", restoreKeyboard)
        editBox:HookScript("OnHide", restoreKeyboard)
        hooked[editBox] = false
    end
    if not editBox:IsKeyboardEnabled() then
        -- Restore this flag on blur only when LayoutFix enabled it.
        hooked[editBox] = true
        editBox:EnableKeyboard(true)
    end
end

function LayoutFix:InstallChatHook()
    if self.usesTabShortcut then
        -- WotLK explicitly calls this extension point before its own Tab action.
        local original = ChatEdit_CustomTabPressed
        ChatEdit_CustomTabPressed = function(...)
            if original(...) then
                return true
            end
            if self:GetTabShortcut() == self.preferences.shortcut then
                local editBox = activeChat()
                if isFocusedChat(editBox) then
                    return convertChat(editBox)
                end
            end
        end
        return
    elseif ChatFrameUtil and ChatFrameUtil.ActivateChat then
        hooksecurefunc(ChatFrameUtil, "ActivateChat", hookChat)
    elseif ChatEdit_ActivateChat then
        hooksecurefunc("ChatEdit_ActivateChat", hookChat)
    end
    hookChat(activeChat())
end
