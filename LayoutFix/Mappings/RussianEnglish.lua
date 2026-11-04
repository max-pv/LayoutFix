local _, LayoutFix = ...

-- Standard US QWERTY and Russian ЙЦУКЕН keys, including their shifted positions.
LayoutFix:RegisterMapping({
    id = "ru-en",
    name = "English (QWERTY) / Russian (ЙЦУКЕН)",
    rows = {
        { [=[`qwertyuiop[]\]=], [=[ёйцукенгшщзхъ\]=] },
        { [=[~QWERTYUIOP{}|]=], "ЁЙЦУКЕНГШЩЗХЪ/" },
        { "asdfghjkl;'", "фывапролджэ" },
        { 'ASDFGHJKL:"', "ФЫВАПРОЛДЖЭ" },
        { "zxcvbnm,./", "ячсмитьбю." },
        { "ZXCVBNM<>?", "ЯЧСМИТЬБЮ," },
        { [[!@#$%^&*()]], [[!"№;%:?*()]] },
    },
    evidence = {
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ",
    },
})
