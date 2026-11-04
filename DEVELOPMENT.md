# LayoutFix development and compatibility

LayoutFix corrects a draft typed with the wrong keyboard layout in the default World of Warcraft chat box. It swaps characters by physical key position. For example, `ghbdtn` becomes `привет`, `Ghbdtn` becomes `Привет`, and `руддщ` becomes `hello`.

See the [README](README.md) for installation and the default shortcut.

## Configuration

- **3.3.5a** · Esc → Interface → AddOns → LayoutFix
- **Classic Era and Retail** · Esc → Options → AddOns → LayoutFix
- Select **Assign key** and press **Shift+Tab** or **Ctrl+Tab** on 3.3.5a, or an unmodified **F1–F12** key on Classic Era and Retail. Esc cancels. The function-key settings warn if WoW reports another binding for that key. LayoutFix leaves the game's binding table alone.
- Use **Reset shortcut** to restore the client default. Use **Keyboard mapping** to switch layouts or reselect the original English/Russian mapping. The mapping and shortcut save account-wide on normal client exit or `/reload`. On 3.3.5a, previously saved function keys fall back to **Shift+Tab**.
- The settings panel follows the WoW client language. It includes Russian, German, French, Spanish (`esES` and `esMX`), and Brazilian Portuguese, with English as the fallback.

## Conversion rules

- Direction comes from the mapped letters in the message. Evidence from only one layout selects that direction. If the draft contains evidence from both layouts or neither, it stays as typed. Numbers and most symbols provide no evidence. When the direction is clear, the selected layout converts mapped symbols and preserves unknown characters.
- The shortcut applies only to the focused default chat EditBox. Parsed routes such as Guild, Party, Raid, numbered channels and whispers stay in Blizzard's chat state. When a supported prefix is still in the draft, LayoutFix preserves the prefix and the target before converting the body. For legacy raw whispers it treats the first token as the character name. Resolve multiword recipients through Blizzard's chat UI before converting.
- Non-chat slash commands, in-progress IME composition, and drafts with WoW chat markup such as item links are skipped. A conversion is also skipped if it would create slash-command syntax, produce chat markup, change a modern raw whisper target, or exceed the EditBox's reported byte limit.
- LayoutFix restores the caret by translating the UTF-8 byte offset. The target EditBox APIs expose a caret position and a way to set a selection, but expose no selection-range getter. An existing selection may collapse when the text is replaced.

## Keyboard support

3.3.5a exposes separate left and right Ctrl state queries. Its XML schema includes `OnKeyDown` and `OnKeyUp`, but a function-key probe failed to reach the focused chat EditBox on the tested 3.3.5a-derived client. A **Shift+Tab** probe reached its dedicated Tab handler and detected Shift. LayoutFix uses Blizzard's chat Tab extension point on that path, after any active autocomplete handler. Plain Tab and chords that produce no conversion fall through to Blizzard's usual behavior. Standalone Right Ctrl remains unsupported. [3.3.5a client API registration extract](https://github.com/brues-code/ClassicAPI/blob/master/docs/BlizzardScriptAPI_3.3.5.md#main-misc-framexml-core-0x00ac80b0--310) · [Blizzard's 3.3.5a chat Tab handler](https://github.com/wowgaming/3.3.5-interface-files/blob/main/ChatFrame.lua#L3653-L3659)

On modern clients the runtime post-hooks Blizzard's chat activation and listens on that EditBox while it has focus. If LayoutFix enables keyboard input on a box, it restores the flag when the box loses focus or hides. Key assignment uses a separate keyboard listener only while the panel is capturing. Native key repeat and interactions with existing bindings and chat addons still need in-game checks. [Retail chat activation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua) · [Retail chat and whisper parser](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua)

## Compatibility

| Client | Interface | Implementation and automated coverage | In-game verification |
| --- | --- | --- | --- |
| Original WoW 3.3.5a (WotLK) | `30300` | Primary target. Legacy chat, settings, and dropdown paths exercised with mocks. | Pending |
| Whitemane Frostmourne Rebuffed (3.3.5a-derived) | `30300` | Uses the legacy Tab shortcut. | Partial verification. After `/reload`, Shift+Tab converted `Ghbdtn` → `Привет` → `Ghbdtn` in a focused Say draft without sending it. See the checklist below for remaining checks. |
| Official Classic Era 1.15.9 | `11509` | Flavor manifest and modern chat and settings paths exercised with mocks. Likely compatible based on the client UI source. | Pending |
| Retail 12.1.5 | `120105` | Flavor manifest and modern chat and settings paths exercised with mocks. Likely compatible based on the client UI source. | Pending |
| Other legacy and official Classic branches | Varies | No targeted manifests or compatibility verification. Clients lacking both supported chat activation APIs cannot use the shortcut. | Unverified |

The shared code detects the chat, settings, and menu APIs independently. The TOCs all load the same XML manifest. Interface numbers target the client versions listed above. [Classic Era chat source](https://github.com/Gethe/wow-ui-source/blob/1.15.9/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua) · [Classic Era build](https://github.com/Gethe/wow-ui-source/blob/classic_era/version.txt) · [Retail build](https://github.com/Gethe/wow-ui-source/blob/live/version.txt) · [Blizzard canvas settings guide](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_ImplementationReadme.lua) · [Blizzard dropdown guide](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua)

## Adding a mapping

The included US English pairs cover Russian ЙЦУКЕН, Ukrainian (Enhanced), Greek, Hebrew (Standard), Arabic (101), and Thai Kedmanee. The new mappings were checked against the Windows diagrams for unshifted and Shift states on the common US keyboard positions. Dead keys, AltGr, ISO-only positions and keys that output multiple characters are outside the one-character mapping. Client fonts and script rendering still need in-game verification for the additional languages. [Ukrainian](https://learn.microsoft.com/globalization/keyboards/kbdur1) · [Greek](https://learn.microsoft.com/globalization/keyboards/kbdhe) · [Hebrew](https://learn.microsoft.com/globalization/keyboards/kbdhebl3) · [Arabic](https://learn.microsoft.com/globalization/keyboards/kbda1) · [Thai](https://learn.microsoft.com/globalization/keyboards/kbdth0)

1. Create a UTF-8 Lua file in [`LayoutFix/Mappings/`](LayoutFix/Mappings/) following [`RussianEnglish.lua`](LayoutFix/Mappings/RussianEnglish.lua). Use a stable ID and a display name.
2. Define paired rows as two strings of equal character count. Each character may occur once per side. Use `evidence` to list mapped characters unique to each direction, typically letters. The registry derives the reverse lookup from the same rows and returns `nil, reason` for rejected definitions.
3. Register from the module using the addon's private table and add one `<Script file="Mappings\YourMapping.lua"/>` entry after `Core.lua` in [`LayoutFix/Load.xml`](LayoutFix/Load.xml). WoW loads explicitly listed files. The settings dropdown reads the registry, so no UI or conversion code changes are needed.
4. Add representative conversion, direction, and round-trip assertions in [`Tests/run.lua`](Tests/run.lua). Reload the game and verify the mapping appears and can be selected.

```lua
local _, LayoutFix = ...
LayoutFix:RegisterMapping({
    id = "example",
    name = "Example",
    rows = { { "ab!", "αβ¡" } },
    evidence = { "ab", "αβ" },
})
```

## Development

Run the dependency-free tests from the repository root with Lua 5.1 or later.

```sh
lua Tests/run.lua
```

The suite covers the mapping registry, UTF-8 conversion and cursor offsets, chat routing and focus with mocked clients, shortcut capture, persistence, and all shipped load manifests. Keep the runtime Lua 5.1-compatible.

| Path | Purpose |
| --- | --- |
| [`LayoutFix/Core.lua`](LayoutFix/Core.lua) | Registry, conversion and preference validation independent of WoW |
| [`LayoutFix/Chat.lua`](LayoutFix/Chat.lua) | Active chat, keyboard hook, message boundaries and text replacement |
| [`LayoutFix/Settings.lua`](LayoutFix/Settings.lua) | Options UI, keyboard capture and SavedVariables |
| [`LayoutFix/Mappings/`](LayoutFix/Mappings/) | One self-registering file per mapping |
| [`Tests/`](Tests/) | Test runner and small WoW API mocks |
| [`AGENTS.md`](AGENTS.md) | Repository development instructions |

## Manual release checklist

Checked items record results on Whitemane Frostmourne Rebuffed (`30300`). Run the full checklist separately on an original 3.3.5a client with other addons disabled, and on each additional client before marking it as verified.

- [x] After `/reload`, press Shift+Tab in a focused Say draft to convert `Ghbdtn` → `Привет` → `Ghbdtn`. Confirm the draft stays unsent.
- [ ] Enable Lua errors, load LayoutFix, and verify the options panel opens and displays the client default shortcut and the English/Russian mapping.
- [ ] Expand conversion coverage to `ghbdtn`, `руддщ`, and `GHBDTN`. Check `ё`, `Ё`, punctuation, digits, spaces, and mixed-script drafts.
- [ ] Verify Guild, Party, Raid, a numbered channel, and whispers. Check the channel or recipient before and after conversion.
- [ ] Verify slash commands such as `/run ghbdtn` stay intact and linked items survive a shortcut press.
- [ ] Convert with the caret in the middle of the draft. Continue typing, check that focus stays in chat, and confirm the shortcut never sends a message.
- [ ] Check Enter, Esc, Backspace, plain Tab, arrow keys, and paste with chat focused. Hold the configured shortcut, try other modifiers, and check that normal gameplay bindings work when chat is closed.
- [ ] Assign another supported shortcut. On modern clients, check the binding warning. Reject an unsupported key, cancel with Esc, and reset to the client default.
- [ ] Repeat in Classic and IM chat styles where available, including a separate whisper window and an IM box that is visible but unfocused.
- [ ] Register a temporary second mapping using the example above. Check that both appear and selecting either changes conversion.
- [ ] Verify shortcut and mapping settings survive `/reload` and a full client restart.

LayoutFix is published under the [MIT license](LICENSE), added to `main` in `fa9e0a3`.
