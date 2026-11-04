local _, LayoutFix = ...

-- Windows layout diagram: https://learn.microsoft.com/globalization/keyboards/kbda1.html
-- Lam-alef keys emit multiple characters and are omitted.
LayoutFix:RegisterMapping({
    id = "ar-en",
    name = "English / Arabic (101)",
    rows = {
        { "`", "ذ" },
        { "qwertyuiop[]", "ضصثقفغعهخحجد" },
        { "asdfghjkl;'", "شسيبلاتنمكط" },
        { "zxcvnm,./", "ئءؤرىةوزظ" },
        { "~()", "ّ)(" },
        { "QWERYUIOP{}", "ًٌَُإ‘÷×؛<>" },
        { "ASDFHJKL", "ٍِ][أـ،/" },
        { "ZXCVNM<>?", "~ْ}{آ’,.؟" },
    },
    evidence = { "qwertyuiopasdfghjklzxcvnmQWERYUIOPASDFHJKLZXCVNM", "ذضصثقفغعهخحجدشسيبلاتنمكطئءؤرىةوزظإأـآ" },
})
