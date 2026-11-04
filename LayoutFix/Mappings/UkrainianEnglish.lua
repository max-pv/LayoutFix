local _, LayoutFix = ...

-- Windows layout diagram: https://learn.microsoft.com/globalization/keyboards/kbdur1.html
-- Uses the ANSI keys shared with US QWERTY, without AltGr or the ISO extra key.
LayoutFix:RegisterMapping({
    id = "uk-en",
    name = "English / Ukrainian (Enhanced)",
    rows = {
        { "`", "'" },
        { "qwertyuiop[]", "йцукенгшщзхї" },
        { "asdfghjkl;'", "фівапролджє" },
        { "zxcvbnm,./", "ячсмитьбю." },
        { "~@#$^&", "₴\"№;:?" },
        { "QWERTYUIOP{}|", "ЙЦУКЕНГШЩЗХЇ/" },
        { "ASDFGHJKL:\"", "ФІВАПРОЛДЖЄ" },
        { "ZXCVBNM<>?", "ЯЧСМИТЬБЮ," },
    },
    evidence = { "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM", "йцукенгшщзхїфівапролджєячсмитьбюЙЦУКЕНГШЩЗХЇФІВАПРОЛДЖЄЯЧСМИТЬБЮ" },
})
