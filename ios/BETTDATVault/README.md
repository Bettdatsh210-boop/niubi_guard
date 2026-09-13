# BETTDAT Vault

**Brand:** @bettdat (BETTDAT LLC)  
**Product:** On-device encrypted vault for notes, photos, and PDFs  
**Platform:** iPhone · iOS 18+ · SwiftUI  

No backend, no cloud sync, no third-party SDKs, no analytics. Encryption uses Apple **CryptoKit** (AES-GCM). The vault key is stored in the iOS **Keychain** (`WhenUnlockedThisDeviceOnly`). Unlock uses **LocalAuthentication** (Face ID with device passcode fallback).

> **Scope:** This app protects content you store *inside* BETTDAT Vault on this iPhone.  
> It does **not** secure Gmail, Stripe, Grok Bot, or any other external account or service.

---

## Open in Xcode

1. Copy or unzip this project onto a Mac with **Xcode 16+** installed.
2. Open `BETTDATVault.xcodeproj` (double-click or `open BETTDATVault.xcodeproj`).
3. Wait for indexing to finish.

If the `.xcodeproj` ever needs regeneration and you have [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
cd /path/to/BETTDATVault
xcodegen generate
open BETTDATVault.xcodeproj
```

---

## Install on a physical iPhone 16 (personal Apple ID)

Apple lets you run your own apps on your devices with a free **Personal Team** (Apple ID). Apps signed this way typically expire after ~7 days and must be reinstalled.

1. Connect the **iPhone 16** with a cable (or set up wireless debugging after the first trust).
2. On the iPhone: **Settings → Privacy & Security → Developer Mode** → enable if prompted, then restart.
3. Unlock the phone and tap **Trust** if asked.
4. In Xcode, select the **BETTDATVault** scheme and your **iPhone** as the run destination (not a simulator).
5. Select the project in the navigator → **Signing & Capabilities**:
   - Check **Automatically manage signing**
   - **Team:** choose your personal Apple ID (Add Account… under Xcode → Settings → Accounts if needed)
   - **Bundle Identifier:** `com.bettdat.vault` (change to something unique like `com.yourname.bettdatvault` if Xcode reports a conflict)
6. First build may ask for Keychain access / codesign permissions — allow them.
7. Press **Run** (▶). After install, on the iPhone go to **Settings → General → VPN & Device Management** (or **Device Management**) and **Trust** your developer certificate.
8. Launch **BETTDAT Vault**. Grant **Face ID** when prompted (`NSFaceIDUsageDescription` is already in Info.plist).

Simulator notes: Face ID can be simulated via **Features → Face ID**. Prefer a physical device for Keychain + real biometrics testing.

---

## Features

| Area | Behavior |
|------|----------|
| Lock | Face ID / biometrics; falls back to device passcode via `deviceOwnerAuthentication` |
| Re-lock | Locks when the app backgrounds (default: Face ID every open + immediate auto-lock) |
| App switcher | Privacy overlay hides vault content in snapshots |
| Vault | Encrypted notes + imported photos/PDFs on device |
| Access log | Success / fail / lock events with timestamps (full log after unlock; lock screen shows last failed attempt time only) |
| Settings | Face ID every open, auto-lock (Immediate / 1 min / 5 min), wipe log, emergency lock |

---

## Project layout

```
BETTDATVault/
├── BETTDATVault.xcodeproj/
├── BETTDATVault/
│   ├── BETTDATVaultApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   ├── Utilities/
│   └── Assets.xcassets/
├── project.yml          # optional XcodeGen spec
├── README.md
└── TEST.md
```

---

## Privacy & security notes

- Data lives under the app’s Application Support directory as ciphertext.
- There is no account system and no network client in this project.
- A determined attacker with an unlocked, jailbroken, or physically compromised device has more options than a casual observer — treat this as a personal vault layer, not a substitute for full-disk device security and good passcode hygiene.
