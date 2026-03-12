# LZ-SBS — Developer Guide

## Project Overview

A Qt 6 / QML point-of-sale app targeting **Windows** (current) and **Android 8.1+** (planned).  
Products are loaded at runtime from `products.json` — no recompile needed to change the menu.

---

## Toolchain

| Tool | Path |
|------|------|
| Qt 6.10.2 (MinGW 64-bit) | `C:\Qt\6.10.2\mingw_64` |
| MinGW 13.1.0 | `C:\Qt\Tools\mingw1310_64\bin` |
| CMake | `C:\Qt\Tools\CMake_64\bin` |
| Ninja | `C:\Qt\Tools\Ninja` |

---

## Build (Windows — PowerShell)

### Normal rebuild (QML / C++ changes)

```powershell
Stop-Process -Name "appLZ_SBS" -ErrorAction SilentlyContinue
$env:PATH = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\CMake_64\bin;C:\Qt\Tools\Ninja;$env:PATH"
cmake --build "C:\Users\inku9\source\repos\Test1_Kassensystem\build"
```

### Full reconfigure + build (after editing CMakeLists.txt)

```powershell
Stop-Process -Name "appLZ_SBS" -ErrorAction SilentlyContinue
$env:PATH = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\CMake_64\bin;C:\Qt\Tools\Ninja;$env:PATH"
cmake -B "C:\Users\inku9\source\repos\Test1_Kassensystem\build" `
      -S "C:\Users\inku9\source\repos\Test1_Kassensystem" `
      -G Ninja -DCMAKE_BUILD_TYPE=Debug `
      "-DCMAKE_PREFIX_PATH=C:/Qt/6.10.2/mingw_64"
cmake --build "C:\Users\inku9\source\repos\Test1_Kassensystem\build"
```

### Launch

```powershell
$env:PATH = "C:\Qt\6.10.2\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;$env:PATH"
Start-Process "C:\Users\inku9\source\repos\Test1_Kassensystem\build\appLZ_SBS.exe"
```

> **Important:** Always stop the running app before rebuilding — Windows locks the `.exe` file while it's running.

---

## File Structure

```
Test1_Kassensystem/
├── CMakeLists.txt        # Build definition
├── main.cpp              # Entry point (loads QML module "LZ_SBS")
├── Main.qml              # Full UI definition
├── productconfig.h       # C++ class: reads products.json → QVariantList
├── productconfig.cpp
├── products.json         # Runtime product config (edit freely, no recompile)
├── build/
│   ├── appLZ_SBS.exe     # Compiled executable
│   └── products.json     # Auto-copied here by CMake configure_file()
└── DEV_GUIDE.md          # This file
```

---

## Editing Products

Open `products.json` and add/remove/modify entries:

```json
{
    "products": [
        { "name": "Roster",    "price": 3.50 },
        { "name": "Steak",     "price": 4.00 },
        { "name": "ZWB",       "price": 2.50 },
        { "name": "Cola",      "price": 2.00 },
        { "name": "Limo",      "price": 1.80 },
        { "name": "Bier",      "price": 2.50 },
        { "name": "Waffel",    "price": 2.00 },
        { "name": "Speckfett", "price": 2.00 },
        { "name": "Schnaps",   "price": 1.50 }
    ]
}
```

After saving, **copy the file to `build\`** (or do a full reconfigure so `configure_file()` picks it up):

```powershell
Copy-Item "C:\Users\inku9\source\repos\Test1_Kassensystem\products.json" `
          "C:\Users\inku9\source\repos\Test1_Kassensystem\build\products.json"
```

Then restart the app — no rebuild required.

---

## UI Layout

```
┌─ Artikel ─────────────────┐  ┌─ Kassenzettel ──────────┐
│  [Roster] [Steak] [ZWB]   │  │  Roster x1   3,50 €     │
│  [Cola]   [Limo]  [Bier]  │  │  ─────────────────────  │
│  [Waffel] [Speckfett]...  │  │  Gesamt: 3,50 €         │
└───────────────────────────┘  │                         │
                               │  ┌─ Manuelle Eingabe ─┐ │
                               │  │ [7][8][9][DEL]      │ │
                               │  │ [4][5][6]           │ │
                               │  │ [1][2][3]           │ │
                               │  │ [  0  ][RDY]        │ │
                               │  └────────────────────┘ │
                               └─────────────────────────┘
```

- **Product buttons** — click to add 1 item (or enter quantity on numpad first, then click)
- **Manuelle Eingabe numpad** — type a quantity before clicking a product button
- **DEL** — clears the current number input
- **RDY** — clears the entire order (receipt + total)

---

## Android Build (Planned)

1. Install **Android Studio** (provides SDK, NDK, JDK)
2. Open Qt Creator → `Edit → Preferences → Devices → Android` → let it auto-detect
3. Open project: `File → Open File or Project → CMakeLists.txt`
4. Switch kit to **Android arm64-v8a**
5. Set minimum API level to **27** (Android 8.1) in `AndroidManifest.xml`
6. Build & deploy to device or emulator

---

## Known Issues

| Issue | Notes |
|-------|-------|
| CMake Vulkan warning | `Could NOT find WrapVulkanHeaders` — harmless, ignore it |
| Windows exe lock | Stop the app before rebuilding (`Stop-Process -Name "appLZ_SBS"`)|
| `ApplicationWindow` icon | Does not support `icon.source` — do not add it |
