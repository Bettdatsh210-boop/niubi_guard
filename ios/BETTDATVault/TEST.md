# BETTDAT Vault — Manual Test Plan

Use a physical **iPhone** with Face ID enrolled (or Simulator with Face ID configured). Build and run from Xcode first.

## 1. Lock / unlock (happy path)

1. Launch the app. Confirm the **lock screen** appears (dark UI, “BETTDAT Vault”, unlock button).
2. Tap **Unlock with Face ID** (or allow the automatic prompt).
3. Authenticate successfully.
4. Confirm the **Vault** home appears (empty state or item list).

**Pass:** Vault content is only visible after successful authentication.

---

## 2. Fail Face ID, then see the log

1. From the unlocked vault, background the app (or use Settings → Emergency lock) so it re-locks.
2. On the lock screen, trigger Face ID and **fail** intentionally (wrong face / Simulator → Features → Face ID → Non-matching Face).
3. Confirm a failure message can appear and the vault stays locked.
4. Unlock successfully.
5. Open the **Access Log** (toolbar list icon).
6. Confirm entries for **Unlock failed** and **Unlock succeeded** with timestamps.

**Pass:** Failed attempts are recorded; full log is only viewable after unlock.

---

## 3. Lock screen shows last failed-attempt time only

1. After at least one failed unlock, return to the lock screen (lock the app).
2. Confirm the lock screen shows **Last failed attempt** with a date/time.
3. Confirm it does **not** show the full access log or vault items.

**Pass:** Only the last failed-attempt timestamp is exposed while locked.

---

## 4. Add a note

1. Unlock the vault.
2. Tap **+** → **New Note**.
3. Enter a title and body → **Save**.
4. Confirm the note appears in the list.
5. Open it; confirm the body decrypts and displays correctly.
6. Optional: force-quit and relaunch; unlock; confirm the note still opens.

**Pass:** Note persists encrypted on device and decrypts after unlock.

---

## 5. Background re-lock + app-switcher privacy

Preconditions: Settings → **Face ID every open** ON, **Auto-lock** = Immediate (defaults).

1. Unlock and open a note so vault content is on screen.
2. Swipe up to the **app switcher** (or Home then app switcher).
3. Confirm the BETTDAT Vault card shows the **privacy cover** (lock branding), not note text.
4. Return to the app.
5. Confirm you are on the **lock screen** and must authenticate again.

**Pass:** Content hidden in snapshots; vault re-locks on background.

---

## 6. Optional checks

| Test | Steps | Expect |
|------|-------|--------|
| Import photo | + → Import Photo | Item listed; opens as image after unlock |
| Import PDF | + → Import PDF | Item listed; PDF viewer after unlock |
| Auto-lock 1 min | Settings → Auto-lock → 1 minute; stay in app | Locks after ~1 minute idle |
| Wipe log | Settings → Wipe access log | Log empty |
| Emergency lock | Settings → Emergency lock | Immediate lock + log event |
| Passcode fallback | Fail Face ID then use device passcode when offered | Unlock succeeds |

---

## Out of scope

- Network / cloud sync
- Securing Gmail, Stripe, Grok Bot, or other external accounts
- Claiming the vault is unhackable
