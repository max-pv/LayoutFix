local _, LayoutFix = ...
local mappings = {}
local defaultMapping = "ru-en"

-- Return the byte width of one Unicode scalar. Keep malformed input byte for byte.
local function characterWidth(text, index)
    local first, second, third, fourth = text:byte(index, index + 3)
    if first < 128 then
        return 1, true
    end
    if second and second >= 128 and second <= 191 then
        if first >= 194 and first <= 223 then
            return 2, true
        end
        if third and third >= 128 and third <= 191 then
            if first >= 224 and first <= 239
                and (first ~= 224 or second >= 160) and (first ~= 237 or second <= 159) then
                return 3, true
            end
            if fourth and fourth >= 128 and fourth <= 191
                and first >= 240 and first <= 244
                and (first ~= 240 or second >= 144) and (first ~= 244 or second <= 143) then
                return 4, true
            end
        end
    end
    return 1, false
end

local function characters(text)
    local index = 1
    return function()
        if index <= #text then
            local width, valid = characterWidth(text, index)
            local last = index + width - 1
            local character = text:sub(index, last)
            index = last + 1
            return character, last, valid
        end
    end
end

local function split(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    local result = {}
    for character, _, valid in characters(text) do
        if not valid then
            return nil
        end
        result[#result + 1] = character
    end
    return result
end

function LayoutFix:RegisterMapping(definition)
    if type(definition) ~= "table"
        or type(definition.id) ~= "string" or not definition.id:match("^[%w_-]+$")
        or type(definition.name) ~= "string" or not definition.name:find("%S")
        or type(definition.rows) ~= "table" or #definition.rows == 0
        or type(definition.evidence) ~= "table" then
        return nil, "Invalid mapping definition"
    end
    if mappings[definition.id] then
        return nil, "Duplicate mapping ID"
    end

    local forward, reverse, votes = {}, {}, {}
    for _, row in pairs(definition.rows) do
        local left = type(row) == "table" and split(row[1])
        local right = type(row) == "table" and split(row[2])
        if not left or not right or #left ~= #right then
            return nil, "Each row must have two equal-length UTF-8 strings"
        end
        for index, source in ipairs(left) do
            local target = right[index]
            if forward[source] or reverse[target] then
                return nil, "Duplicate character on one side of the mapping"
            end
            forward[source], reverse[target] = target, source
        end
    end

    for side, lookup in ipairs({ forward, reverse }) do
        local evidence = split(definition.evidence[side])
        if not evidence then
            return nil, "Both sides need valid direction evidence"
        end
        for _, character in ipairs(evidence) do
            if not lookup[character] or lookup[character] == character or votes[character] then
                return nil, "Direction evidence must identify distinct mapped characters"
            end
            votes[character] = side == 1 and "forward" or "reverse"
        end
    end

    mappings[definition.id] = {
        name = definition.name,
        forward = forward,
        reverse = reverse,
        votes = votes,
    }
    return true
end

function LayoutFix:ListMappings()
    local entries = {}
    for id, mapping in pairs(mappings) do
        entries[#entries + 1] = { id = id, name = mapping.name }
    end
    table.sort(entries, function(left, right)
        if left.name == right.name then
            return left.id < right.id
        end
        return left.name < right.name
    end)
    return entries
end

function LayoutFix:DetectDirection(id, text)
    local mapping = mappings[id]
    if not mapping then
        return nil
    end
    local direction
    for character in characters(text) do
        local vote = mapping.votes[character]
        if vote then
            if direction and direction ~= vote then
                return nil
            end
            direction = vote
        end
    end
    return direction
end

-- The optional cursor counts bytes before the caret, as in WoW's EditBox.
function LayoutFix:Convert(id, text, direction, cursor)
    local mapping = mappings[id]
    direction = direction or self:DetectDirection(id, text)
    if not mapping or (direction ~= "forward" and direction ~= "reverse") then
        return text, cursor
    end
    local lookup = mapping[direction]
    local result, convertedCursor = {}, 0
    for character, last in characters(text) do
        local replacement = lookup[character] or character
        result[#result + 1] = replacement
        if cursor and last <= cursor then
            convertedCursor = convertedCursor + #replacement
        end
    end
    return table.concat(result), cursor and convertedCursor
end

function LayoutFix:IsShortcut(key, usesTab)
    if usesTab then
        return key == "SHIFT-TAB" or key == "CTRL-TAB"
    end
    return type(key) == "string" and (key:match("^F[1-9]$") or key:match("^F1[0-2]$")) ~= nil
end

function LayoutFix:LoadPreferences(saved, usesTab)
    if type(saved) ~= "table" then
        saved = {}
    end
    local mapping = saved.mapping
    if type(mapping) ~= "string" or not mappings[mapping] then
        mapping = defaultMapping
        if not mappings[mapping] then
            local first = self:ListMappings()[1]
            mapping = first and first.id
        end
    end
    local preferences = { mapping = mapping }
    if not self:SelectShortcut(preferences, saved.shortcut, usesTab) then
        self:SelectShortcut(preferences, nil, usesTab)
    end
    return preferences
end

function LayoutFix:SelectMapping(preferences, id)
    if type(id) == "string" and mappings[id] then
        preferences.mapping = id
        return true
    end
end

function LayoutFix:SelectShortcut(preferences, key, usesTab)
    if key == nil or self:IsShortcut(key, usesTab) then
        preferences.shortcut = key or (usesTab and "SHIFT-TAB" or "F8")
        return true
    end
end
