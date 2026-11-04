local _, LayoutFix = ...

-- Windows layout diagram: https://learn.microsoft.com/globalization/keyboards/kbdhe.html
-- The tonos and dialytika dead keys require composition and are omitted.
LayoutFix:RegisterMapping({
    id = "el-en",
    name = "English / Greek",
    rows = {
        { "qwertyuiop", ";ςερτυθιοπ" },
        { "asdfghjkl", "ασδφγηξκλ" },
        { "zxcvbnm", "ζχψωβνμ" },
        { "QERTYUIOP", ":ΕΡΤΥΘΙΟΠ" },
        { "ASDFGHJKL", "ΑΣΔΦΓΗΞΚΛ" },
        { "ZXCVBNM", "ΖΧΨΩΒΝΜ" },
    },
    evidence = { "qwertyuiopasdfghjklzxcvbnmQERTYUIOPASDFGHJKLZXCVBNM", "ςερτυθιοπασδφγηξκλζχψωβνμΕΡΤΥΘΙΟΠΑΣΔΦΓΗΞΚΛΖΧΨΩΒΝΜ" },
})
