local _, LayoutFix = ...

-- Windows layout diagram: https://learn.microsoft.com/globalization/keyboards/kbdth0.html
LayoutFix:RegisterMapping({
    id = "th-en",
    name = "English / Thai Kedmanee",
    rows = {
        { "`1234567890-=", "_ๅ/-ภถุึคตจขช" },
        { "qwertyuiop[]\\", "ๆไำพะัีรนยบลฃ" },
        { "asdfghjkl;'", "ฟหกดเ้่าสวง" },
        { "zxcvbnm,./", "ผปแอิืทมใฝ" },
        { "~!@#$%^&*()_+", "%+๑๒๓๔ู฿๕๖๗๘๙" },
        { "QWERTYUIOP{}|", "๐\"ฎฑธํ๊ณฯญฐ,ฅ" },
        { "ASDFGHJKL:\"", "ฤฆฏโฌ็๋ษศซ." },
        { "ZXCVBNM<>?", "()ฉฮฺ์?ฒฬฦ" },
    },
    evidence = { "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM", "ๅภถคตจขชๆไำพะรนยบลฃฟหกดเาสวงผปแอทมใฝฎฑธณฯญฐฅฤฆฏโฌษศซฉฮฒฬฦ" },
})
