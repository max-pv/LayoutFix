# LayoutFix development instructions

## Project overview

LayoutFix corrects wrong-layout drafts in the default WoW chat input using physical keyboard mappings. Original WoW 3.3.5a (Interface 30300) takes priority. Maintain one source tree for WotLK, official Classic Era, and Retail where the native APIs permit it.

## Repository structure

- `LayoutFix/Core.lua` owns the registry, UTF-8 conversion, direction detection, and preference validation.
- `LayoutFix/Mappings/` contains one self-registering module per layout pair.
- `LayoutFix/Chat.lua` owns WoW chat and keyboard integration. `LayoutFix/Settings.lua` owns settings registration, widgets, and persistence. Keep client API differences in these files.
- `LayoutFix/Locale.lua` supplies localized settings and mapping names with an English fallback.
- `LayoutFix/Load.xml` is the common script list. The flavor TOCs supply loader metadata.
- `Tests/run.lua` runs pure Lua and integration cases. `Tests/WoWMock.lua` provides the minimal client fixtures.

## Development guidelines

- Use readable Lua 5.1 and keep mapping and conversion code independent of WoW.
- Prefer small changes and existing Blizzard UI APIs. Keep version detection close to the API it selects.
- Retain stable mapping IDs and compatibility with existing SavedVariables. Avoid new runtime dependencies.
- Preserve draft text and Blizzard's routing state. Conversion must require a deliberate shortcut in the focused chat box.

## Adding new mappings

Define paired UTF-8 rows and disjoint direction evidence in a new file under `LayoutFix/Mappings/`. Register once through the private addon table and add the file to `LayoutFix/Load.xml` after `Core.lua`. Both dropdowns populate from the registry. Add tests for direction, round trips, case and representative symbols. See the example in `DEVELOPMENT.md`.

## Testing instructions

Run from the repository root with Lua 5.1 or later.

```sh
lua Tests/run.lua
```

Expect every case to pass and the final line to print the test count and Lua version. For changes to client behavior, run the relevant checklist items in `DEVELOPMENT.md` on a real 3.3.5a client. Record the exact client version when verifying other flavors.

## Code review rules

- Check every changed WoW API against 3.3.5a and guard newer calls.
- Check UTF-8 boundaries, one-to-one mappings, reversible positions, and ambiguous inputs.
- Check slash commands, chat prefixes, whisper targets, and parsed routing. Review focus, cursor offsets, length limits, inactive chat, and binding conflicts.
- Check that the shortcut path neither sends messages nor modifies game bindings. Prefer post-hooks and avoid intercepting unrelated input.
- Remove unnecessary abstractions and require regression tests for behavioral changes.

## Documentation requirements

Keep the README short and update its installation or usage steps when they change. Update mapping details, test commands, limitations and the compatibility matrix in `DEVELOPMENT.md`. Keep automated coverage and actual in-game results distinct.
