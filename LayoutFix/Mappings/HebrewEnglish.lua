local _, LayoutFix = ...

-- Windows layout diagram: https://learn.microsoft.com/globalization/keyboards/kbdhebl3.html
LayoutFix:RegisterMapping({
    id = "he-en",
    name = "English / Hebrew (Standard)",
    rows = {
        { "`", ";" },
        { "qwertyuiop[]", "/'קראטוןםפ][" },
        { "asdfghjkl;'", "שדגכעיחלךף," },
        { "zxcvbnm,./", "זסבהנמצתץ." },
        { "()", ")(" },
        { "{}", "}{" },
        { "<>", "><" },
    },
    evidence = { "qwertyuiopasdfghjklzxcvbnm", "קראטוןםפשדגכעיחלךףזסבהנמצתץ" },
})
