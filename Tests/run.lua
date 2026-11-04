-- Run from the repository root with Lua 5.1 or later.
local passed = 0

local function equal(actual, expected)
    assert(actual == expected, ("expected %q, got %q"):format(tostring(expected), tostring(actual)))
end

local function test(name, run)
    local ok, err = pcall(run)
    if not ok then
        error(name .. "\n" .. err, 0)
    end
    passed = passed + 1
    print("PASS " .. name)
end

local function loadAddonFile(addon, path)
    assert(loadfile("LayoutFix/" .. path))("LayoutFix", addon)
end

local function loadCore()
    local addon = {}
    loadAddonFile(addon, "Core.lua")
    loadAddonFile(addon, "Mappings/RussianEnglish.lua")
    return addon
end

local mockMapping = {
    id = "test",
    name = "A test layout",
    rows = { { "gh!", "αβ¡" } },
    evidence = { "gh", "αβ" },
}

local core = loadCore()
local id = "ru-en"

test("English and Russian, case and spaces", function()
    equal(core:Convert(id, "ghbdtn"), "привет")
    equal(core:Convert(id, "руддщ"), "hello")
    equal(core:Convert(id, "Ghbdtn"), "Привет")
    equal(core:Convert(id, "GHBDTN"), "ПРИВЕТ")
    equal(core:Convert(id, "Пp"), "Пp")
    equal(core:Convert(id, "  GhBdTn  vbh "), "  ПрИвЕт  мир ")
end)

test("Numbers, shifted symbols, punctuation and both forms of ё", function()
    equal(core:Convert(id, "gh 0123456789 `~!@#$%^&*()[]{};':\",./<>?\\|"),
        "пр 0123456789 ёЁ!\"№;%:?*()хъХЪжэЖЭбю.БЮ,\\/")
    equal(core:Convert(id, "ёЁпривет."), "`~ghbdtn/")
end)

test("Empty and neutral text, Unicode and malformed bytes", function()
    equal(core:Convert(id, ""), "")
    equal(core:Convert(id, " 0123?! "), " 0123?! ")
    equal(core:Convert(id, "gh 😀 café 中"), "пр 😀 сфаé 中")
    equal(core:Convert(id, "gh\255\128"), "пр\255\128")
end)

test("Direction detection and mixed-script safety", function()
    equal(core:DetectDirection(id, "gh!"), "forward")
    equal(core:DetectDirection(id, "Ё!"), "reverse")
    equal(core:DetectDirection(id, "123,."), nil)
    equal(core:DetectDirection(id, "привет world"), nil)
    equal(core:Convert(id, "ghbdtn я"), "ghbdtn я")
    equal(core:Convert(id, "gh я", "forward"), "пр я")
    equal(core:Convert(id, "gh", "unknown"), "gh")
    equal(core:Convert("missing", "gh", "forward"), "gh")
end)

test("Round trip and UTF-8 cursor byte offsets", function()
    local text = "Ghbdtn, vbh! `~$% ^ 😊"
    equal(core:Convert(id, (core:Convert(id, text, "forward")), "reverse"), text)
    local punctuation = "[].,/?%!"
    equal(core:Convert(id, (core:Convert(id, punctuation, "forward")), "reverse"), punctuation)
    local converted, cursor = core:Convert(id, "gh😀", nil, 2)
    equal(converted, "пр😀")
    equal(cursor, 4)
    converted, cursor = core:Convert(id, converted, nil, 4)
    equal(converted, "gh😀")
    equal(cursor, 2)
    converted, cursor = core:Convert(id, "пр", nil, 1)
    equal(cursor, 0)
end)

test("Invalid mappings are rejected without changing the registry", function()
    equal(core:RegisterMapping(false), nil)
    local invalidRows = {
        false, {}, { false }, { { "", "ф" } }, { { "ab", "ф" } },
        { { "aa", "фы" } }, { { "ab", "фф" } },
        { { "a", "\192\128" } }, { { "a", "\237\160\128" } },
        { { "a", "\244\144\128\128" } },
        { { "a", "\226\130" } },
    }
    for _, rows in ipairs(invalidRows) do
        equal(core:RegisterMapping({ id = "bad", name = "Bad", rows = rows, evidence = { "a", "ф" } }), nil)
    end
    equal(core:RegisterMapping({
        id = "bad", name = "Bad", rows = { { "ab", "ba" } }, evidence = { "a", "a" },
    }), nil)
    equal(#core:ListMappings(), 1)
end)

test("Mapping registration, duplicate rejection and switching", function()
    equal(core:RegisterMapping(mockMapping), true)
    equal(core:RegisterMapping(mockMapping), nil)
    local entries = core:ListMappings()
    equal(#entries, 2)
    equal(entries[1].id, "test")
    local preferences = core:LoadPreferences()
    equal(preferences.mapping, id)
    equal(core:SelectMapping(preferences, "test"), true)
    equal(core:Convert(preferences.mapping, "gh!"), "αβ¡")
    equal(core:Convert(preferences.mapping, "αβ¡"), "gh!")
    equal(core:SelectMapping(preferences, "missing"), nil)
    equal(core:LoadPreferences(preferences).mapping, "test")
    equal(core:SelectMapping(preferences, id), true)
    equal(core:Convert(preferences.mapping, "gh"), "пр")
end)

test("Default, invalid and saved preferences", function()
    equal(core:LoadPreferences().shortcut, "F8")
    equal(core:LoadPreferences(false).mapping, id)
    local loaded = core:LoadPreferences({ mapping = {}, shortcut = "RCTRL", removedOption = true })
    equal(loaded.mapping, id)
    equal(loaded.shortcut, "F8")
    equal(loaded.removedOption, nil)
    loaded = core:LoadPreferences({ mapping = "test", shortcut = "F12" })
    equal(loaded.mapping, "test")
    equal(loaded.shortcut, "F12")
    for _, key in ipairs({ "F0", "F01", "F13", "ENTER", "A", "CTRL-F8", "RCTRL", false }) do
        equal(core:SelectShortcut(loaded, key), nil)
        equal(loaded.shortcut, "F12")
    end
    equal(core:SelectShortcut(loaded), true)
    equal(loaded.shortcut, "F8")
end)

local extraMappings = {
    { file = "UkrainianEnglish.lua", id = "uk-en", left = "GHBDSN [] ~", right = "ПРИВІТ хї ₴" },
    { file = "GreekEnglish.lua", id = "el-en", left = "GEIA w?", right = "ΓΕΙΑ ς?", omitted = ";" },
    { file = "HebrewEnglish.lua", id = "he-en", left = "(akuo)", right = ")שלום(" },
    { file = "ArabicEnglish.lua", id = "ar-en", left = "lvpfh?", right = "مرحبا؟", omitted = "b" },
    { file = "ThaiEnglish.lua", id = "th-en", left = "l;ylfu!", right = "สวัสดี+" },
}
for _, example in ipairs(extraMappings) do
    test(example.id .. " physical positions, reverse conversion and mixed-script safety", function()
        local addon = loadCore()
        loadAddonFile(addon, "Mappings/" .. example.file)
        equal(#addon:ListMappings(), 2)
        equal(addon:Convert(example.id, example.left), example.right)
        equal(addon:Convert(example.id, example.right), example.left)
        equal(addon:Convert(example.id, example.left .. " 🙂"), example.right .. " 🙂")
        equal(addon:Convert(example.id, "abc " .. example.right), "abc " .. example.right)
        if example.omitted then
            equal(addon:Convert(example.id, example.left .. example.omitted), example.right .. example.omitted)
        end
    end)
end

local newClient = assert(loadfile("Tests/WoWMock.lua"))()

for _, variant in ipairs({ "legacy", "modern", "era" }) do
    local client = newClient(variant)
    local addon = client:Boot({ shortcut = "F8" })
    local editBox = client:OpenChat()
    local legacy = variant == "legacy"
    local default = legacy and "SHIFT-TAB" or "F8"
    local alternate = legacy and "CTRL-TAB" or "F12"
    local function convert(box)
        client:Shortcut(box, default)
    end

    test(variant .. " active chat only, preserving focus and cursor", function()
        editBox.text, editBox.cursor = "Ghbdtn", 2
        client:Key(editBox, "F7")
        if legacy then
            client:Key(editBox, "TAB")
            equal(editBox.normalTabs, 1)
            client.tabHandled = true
            convert(editBox)
            equal(editBox.writes, 0)
            client.tabHandled = false
        end
        client.modified = true
        convert(editBox)
        client.modified = false
        equal(editBox.text, "Ghbdtn")
        convert(editBox)
        equal(editBox.text, "Привет")
        equal(editBox.cursor, 4)
        equal(editBox.focused, true)
        equal(editBox.writes, 1)
        client:CloseChat()
        equal(editBox.keyboard, false)
        convert(editBox)
        equal(editBox.writes, 1)
        client:OpenChat(editBox)
        convert(editBox)
        equal(editBox.text, "Ghbdtn")
        equal(editBox.cursor, 2)
        equal(editBox.writes, 2)
        editBox:Hide()
        equal(editBox.keyboard, false)
        editBox:Fire("OnKeyDown", "F8")
        equal(editBox.writes, 2)
        editBox:Show()
        client:OpenChat(editBox)
    end)

    test(variant .. " raw chat prefixes, targets and unrelated commands", function()
        for _, prefix in ipairs({ "/g ", "/p  ", "/raid ", "/s ", "/2 ", "/c General ",
            "/W Player-Realm  ", "/tell Игрок ", "/ш Игрок ", "/r " }) do
            editBox.text, editBox.cursor = prefix .. "ghbdtn", 2
            convert(editBox)
            equal(editBox.text, prefix .. "привет")
            equal(editBox.cursor, 2)
        end
        for _, text in ipairs({ "", "/reload", "/run ghbdtn", "/cast Ghbdtn", "/join General",
            "/w PlayerName", "/w \"First Last\" ghbdtn", "/g /run ghbdtn", " /g ghbdtn",
            "ghbdtn |Hitem:1|h[Item]|h", ".руддщ", "/g .руддщ", "привет world", "123?!" }) do
            local writes = editBox.writes
            editBox.text = text
            convert(editBox)
            equal(editBox.text, text)
            equal(editBox.writes, writes)
        end
        if variant ~= "legacy" then
            editBox.text = "/smartw First Last ghbdtn"
            convert(editBox)
            equal(editBox.text, "/smartw First Last привет")
            editBox.text = "/smartw First ghbdtn"
            convert(editBox)
            equal(editBox.text, "/smartw First ghbdtn")
        end
    end)

    test(variant .. " parsed chat routing, native prefix parsing and length limits", function()
        editBox.route, editBox.target = "WHISPER", "PlayerName"
        editBox.text, editBox.cursor = "руддщ", 4
        convert(editBox)
        equal(editBox.text, "hello")
        equal(editBox.cursor, 2)
        equal(editBox.route, "WHISPER")
        equal(editBox.target, "PlayerName")

        editBox.nativeParsing = true
        editBox.text, editBox.cursor = "/g ghbdtn", 5
        convert(editBox)
        equal(editBox.text, "привет")
        equal(editBox.cursor, 4)
        equal(editBox.route, "GUILD")
        editBox.nativeParsing = false

        editBox.text, editBox.maxBytes = "ghbdtn", 8
        convert(editBox)
        equal(editBox.text, "ghbdtn")
        editBox.maxBytes = nil
        editBox.composing = true
        convert(editBox)
        equal(editBox.text, "ghbdtn")
        editBox.composing = false
        local other = client:OpenChat()
        other.text, other.cursor = "ghbdtn", 6
        convert(editBox)
        convert(other)
        equal(editBox.text, "ghbdtn")
        equal(other.text, "привет")
        client:CloseChat()
    end)

    test(variant .. " key capture, conflict, cancel, reset and dynamic mapping menu", function()
        equal(client.panel.name, "LayoutFix")
        local capture = client.capture
        client.buttons["Assign key"]:Fire("OnClick")
        equal(capture.keyboard, true)
        client:Key(capture, "RCTRL")
        equal(addon.preferences.shortcut, default)
        equal(capture.keyboard, true)
        client:Key(capture, "ESCAPE")
        equal(capture.keyboard, false)
        client.buttons["Assign key"]:Fire("OnClick")
        local assigned = legacy and alternate or "F3"
        client:Shortcut(capture, assigned)
        equal(LayoutFixDB.shortcut, assigned)
        equal(client.panel.labels[5].text, legacy and "" or "This key also has a WoW binding.")
        client.buttons["Reset shortcut"]:Fire("OnClick")
        equal(LayoutFixDB.shortcut, default)
        client.buttons["Assign key"]:Fire("OnClick")
        client.panel:Fire("OnHide")
        equal(capture.keyboard, false)
        client.buttons["Assign key"]:Fire("OnClick")
        client:Shortcut(capture, alternate)

        local builtInCount = 1 + #extraMappings
        equal(#client:OpenDropdown(), builtInCount)
        assert(addon:RegisterMapping(mockMapping))
        local options = client:OpenDropdown()
        equal(#options, builtInCount + 1)
        equal(options[1].text, mockMapping.name)
        options[1].pick()
        equal(LayoutFixDB.mapping, "test")
        local saved = LayoutFixDB
        local reloaded = client:Boot(saved, mockMapping)
        equal(reloaded.preferences.mapping, "test")
        equal(reloaded.preferences.shortcut, alternate)
        local nextBox = client:OpenChat()
        nextBox.text = "gh!"
        convert(nextBox)
        equal(nextBox.text, "gh!")
        client:Shortcut(nextBox, alternate)
        equal(nextBox.text, "αβ¡")
    end)
end

test("settings follow the client locale and fall back to English", function()
    local unpackValues = unpack or table.unpack
    local cases = {
        { "ruRU", "legacy", "Назначить", "Раскладка клавиатуры", "Английская / Греческая" },
        { "deDE", "legacy", "Taste zuweisen", "Tastaturlayout", "Englisch / Griechisch" },
        { "frFR", "modern", "Attribuer une touche", "Disposition du clavier", "Anglais / Grec" },
        { "esES", "modern", "Asignar tecla", "Distribución del teclado", "Inglés / Griego" },
        { "esMX", "modern", "Asignar tecla", "Distribución del teclado", "Inglés / Griego" },
        { "ptBR", "modern", "Atribuir tecla", "Layout do teclado", "Inglês / Grego" },
        { "koKR", "modern", "Assign key", "Keyboard mapping", "English / Greek" },
    }
    for _, case in ipairs(cases) do
        local locale, variant, assignKey, mappingLabel, greekName = unpackValues(case)
        local client = newClient(variant)
        client.locale = locale
        client:Boot(nil, mockMapping)
        assert(client.buttons[assignKey], locale)
        equal(client.panel.labels[6].text, mappingLabel)
        local options = client:OpenDropdown()
        equal(options[1].text, mockMapping.name)
        for _, option in ipairs(options) do
            if option.text == greekName then
                option.pick()
                break
            end
        end
        equal(LayoutFixDB.mapping, "el-en")
    end
end)

print(("%d tests passed on %s"):format(passed, _VERSION))
