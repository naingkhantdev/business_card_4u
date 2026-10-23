# UI/UX Audit — first-run journey & core card loop

**Date:** 2026-10-22
**Scope:** login → register → OTP → complete register → setup profile; card list → add/scan → card detail.
**Method:** code-only. No screenshots were supplied and the app was not run, so **every finding below is "code-only, not visually verified"** unless marked otherwise. Findings marked _verify on device_ are behavioural conclusions from reading the code that should be confirmed before fixing.

**Lenses:** `UX` AGENTS.md UX rules · `TOK` token consistency · `A11Y` accessibility · `MY` Myanmar layout · `DARK` dark-mode parity
**Severity:** **Blocker** (breaks a task) · **Major** (hurts most users / clear rule violation) · **Minor** (polish)

---

## Summary

The design system (`AppColors`, `Wallet`, `Glass`, `AppTypography`) is coherent and well documented, and the newest screens — `OnboardingStepScaffold`, `SetupProfilePage` — already follow it closely. The problems are concentrated in the older, larger pages (`card_page`, `add_card_page`, `otp_page`, `login_page`), which predate the system and still carry a legacy blue-grey palette, raw accent colours that fail in dark mode, and off-token geometry.

| Severity | First-run | Card loop | Cross-cutting | Total |
|---|---|---|---|---|
| Blocker | 0 | 1 | 0 | **1** |
| Major | 5 | 12 | 5 | **22** |
| Minor | 6 | 4 | 2 | **12** |

**Top 5 to fix first**
1. **C1** — Searching the card list for something with no match wipes the query you are typing.
2. **X1/X2** — Myanmar: no Myanmar font, and the tracked 9–10.5 px "eyebrow" style is used for localized labels everywhere.
3. **C3** — Card list uses the light-mode accent in dark mode (~2.3:1 contrast).
4. **C2** — A new user lands on an empty Friends tab whose empty state has no action.
5. **F1** — Onboarding progress appears only on screen 3 and its counter disagrees with its bar.

---

## First-run journey

### F1 · Major · UX — Progress starts late and contradicts itself
`complete_register_page.dart:112-114`, `setup_profile_page.dart:368-370`, `onboarding_step_scaffold.dart:202-205`
Register and OTP show no progress at all; the rail appears on the third screen. There the counter reads **"STEP 1 / 2"** while the bar has **3 segments with 2 filled** (the scaffold adds a segment for email verification). Users see "step 1" after already doing two screens of work.
**Fix:** treat sign-up as 4 steps — *Email · Verify · Account · Your card* — show the same rail on all four (register and OTP too), and derive the counter from the same numbers as the bar (e.g. "STEP 3 / 4").

### F2 · Major · UX/A11Y — OTP can't be pasted or autofilled
`otp_page.dart:698-712`
The real input is a 1 px, zero-opacity `TextField` with no `autofillHints: [AutofillHints.oneTimeCode]`, so iOS/Android code suggestions don't appear and there is no visible field to long-press → Paste. Users must memorise 6 digits from their mail app. No `FilteringTextInputFormatter.digitsOnly` either.
**Fix:** add the one-time-code autofill hint, digits-only formatter, and a "Paste code" text button that appears when the clipboard holds 6 digits.

### F3 · Major · UX — Resend is locked for the full 5-minute expiry
`otp_page.dart:29, 120-121, 264-267`
One constant (`_initialSeconds = 300`) drives both code expiry and the resend cooldown. If the email doesn't arrive, the user waits 5 minutes with no way forward except going back.
**Fix:** separate the two — resend cooldown 30–60 s, expiry shown as copy ("Code valid for 5 minutes").

### F4 · Major · DARK — Login is forced to light mode on phones
`login_page.dart:92-114`
The whole mobile login page overrides the theme to light because the `login.png` illustration was drawn for light backgrounds. In dark mode, the app opens to a bright white screen and then switches to dark after login.
**Fix:** follow the system theme. Either supply a dark variant of the illustration or put the image on a light `Wallet.surfaceOf(false)` plate that reads as intentional in both modes.

### F5 · Major · UX/A11Y — Login form misses basic input affordances; no recovery path
`login_page.dart:217-243, 423-472`
- Email field: no `keyboardType: emailAddress`, no `autofillHints`, no `textInputAction.next`.
- Password field: no `autofillHints: [password]`, no submit-on-enter; password managers won't offer credentials.
- No "Forgot password?" path exists anywhere (no l10n key, no route). → backend proposal **P1**.

### F6 · Minor · UX — Generic or repeated CTAs
| Screen | Current | Suggested |
|---|---|---|
| Register | "Send code" | "Email Me a Code" |
| OTP | "Verify OTP" (reuses the page title) | "Verify & Continue" |
| Add card | "Create card" | "Save to My Cards" |
| Card detail (stranger) | "Connect" | "Send Connect Request" |

Login ("Log In"), Complete register ("Create My Account") and Setup profile ("Save My Card") are already specific.

### F7 · Minor · UX — Forced 1.7 s splash on every cold start
`auth_gate.dart:24-31`. The floor exists so the splash animation finishes, but returning users pay it every launch. Consider a shorter floor or skipping it when a token is already cached.

### F8 · Minor · UX — Auth error state is a dead end
`auth_gate.dart:44-49`. Plain centred text, no retry. Add a "Try Again" button that re-runs the session check.

### F9 · Minor · TOK/DARK — Desktop-web auth branches use a legacy palette
`register_page.dart:24`, `login_page.dart:353`, `otp_page.dart:345-410` — `#5B6473`, navy `#1E3C72`, `Colors.black.withOpacity(...)`, and fixed `Wallet.ink`. These ignore dark mode on web.

### F10 · Minor · TOK — Off-token geometry on auth screens
Login fields radius 14 and a pill button radius 26 (`login_page.dart:272, 433, 444`); OTP glass card 26, buttons/pills 18, pin boxes 16 (`otp_page.dart:255, 493, 535, 573, 740`). Tokens are 10/12/16/20. OTP also builds its own blob background instead of reusing `GlassBackdrop`.

### F11 · Minor · A11Y — Small tap targets on auth chrome
OTP back button 44 dp (`otp_page.dart:537`), onboarding exit button 40 dp (`onboarding_step_scaffold.dart:281-283`). Minimum is 48 dp.

**Worth keeping:** `SetupProfilePage` asks for the card photo first and lets OCR fill the form, treats every field as optional with an honest "Skip for now", and pre-fills from the server's placeholder card while ignoring the fake "Member" position. `_VerifiedEmail` turns finished work into visible progress. These are the patterns to copy elsewhere.

---

## Core card loop

### C1 · Blocker · UX — No-match search erases the user's query _(verify on device)_
`card_page.dart:1265-1288`
The "auto-clear filters if they would hide all cards" block runs on every build. The local filter applies immediately on each keystroke, while `_isFiltering` only turns true after the 350 ms debounce. So the first keystroke that matches nothing clears the search box, drops the selected chip and unfocuses the keyboard. Because of this, the "No matching cards" empty state can never show for the current tab.
**Fix:** delete the auto-clear. Show the existing no-match empty state with a "Clear Filters" button instead. If stale filters after a refresh were the original problem, clear them only on tab switch and after a refresh, never while the user is typing.

### C2 · Major · UX — New users land on an empty tab with no way forward
`card_page.dart:92, 503-557`
The default tab is **Friends** (index 0). Straight after onboarding a new user has no friends, so the first real screen says "No cards yet — Pull down to refresh or add new cards." Pull-to-refresh can't help, and the empty state has no action.
**Fix:**
- Open on whichever tab has cards, falling back to Saved.
- Give each empty state a primary CTA. Saved: **"Scan Your First Card"**. Friends: **"Show My QR"**, with **"Find People"** as the secondary.
- If the user's own card is incomplete, show a small "Your card is 40% done" prompt there.

### C3 · Major · DARK/A11Y — Light-mode accent used in dark mode
`card_page.dart` — tab label/indicator (1336, 1349), profession chips (380-392), filter pill (273-309), filter progress (477), FAB (1612), add-sheet primary tiles (785, 987), empty-state icon (525-530).
`AppColors.primary` (`#6D28D9`) on `Wallet.darkGround` (`#0D0D0F`) is about **2.3:1**, which fails WCAG for text and for UI components. Elsewhere the system already switches to `Wallet.accentOf(isDark)` (`#A78BFA`).
**Fix:** replace every `AppColors.primary` on this page with `Wallet.accentOf(isDark)`, and use `Wallet.onAccentOf(isDark)` for text on filled accent. This is Phase 2 work.

### C4 · Major · UX — The add-card form is long and all equal weight
`add_card_page.dart:546-645, 1193-1319`
Six panels with the same visual weight (Photos, Personal, Company, Contact, Addresses, More). The address block opens with 5 fields and bio is always open. Phones and emails are **comma-separated free text** (`_splitToList`) with no `keyboardType`, so users get the default keyboard and have to type commas.
**Fix:**
- Collapse Addresses and More into "＋ Add address" / "＋ Add note" rows.
- Make phones and emails one field per value, with "＋ Add another", and the right keyboard and `autofillHints`.
- Default the Country field to the most common value (Myanmar).
- After a scan, show a "Review 6 scanned fields" summary at the top instead of making the user hunt for the badges.

### C5 · Major · UX — Leaving add-card loses scanned work without warning
`add_card_page.dart` (no `PopScope`)
After a two-photo scan with OCR, back or swipe-back silently discards the photos and every filled field.
**Fix:** when the form is dirty, wrap it in `PopScope` and show a sheet that states the loss: "Discard this card? 2 photos and 6 scanned fields will be lost." Offer **Keep Editing** as the primary action and **Discard** as the secondary.

### C6 · Major · UX — OCR creates companies on the server without asking
`add_card_page.dart:363-409`
If the OCR'd company name matches nothing on file, the app calls `createMinimal(name)` straight away. That happens before the user saves the card, and it happens even if they later abandon it. A misread such as "ACME C0RP" becomes a permanent company record.
**Fix:** this can be done on the client alone. Show the match as a suggestion chip ("Add 'ACME C0RP' as a new company?" with **Add** / **Choose existing**), and create the company only when the card is saved.

### C7 · Major · TOK/DARK — The add-card form still uses a legacy blue-grey palette
`add_card_page.dart:520, 747, 794-795, 819, 932-946, 1205-1206, 1339-1342, 1362, 1384, 1392-1393, 1428, 1440, 1445, 1478, 1486-1487`
`#F8FAFD`, `#6B7688`, `#8C9DBA`, `#9FB0CC`, `#5B6779`, `#A3ADBD`, `#232F4C`, `#080E1C`, `#0A0F1C` and others are 23 literals in all. In dark mode this form looks navy-tinted next to the neutral list and detail pages. The form also re-implements fields (`_buildPremiumTextField`) instead of using the theme's `InputDecorationTheme`.
**Fix (Phase 2):** map each literal onto `Wallet` tokens, then let the theme's input decoration do the field styling.

### C8 · Major · UX — On a friend's card, the only main button is "Unfriend"
`card_detail_page.dart:1347-1354, 922-937, 970-1012`
For a connected friend, the single full-width button in the body is the **destructive** Unfriend. The useful actions (Call, Email, Map, Website) are four equal 38 dp pills with 12 px labels.
**Fix:**
- Make the first available contact action the primary, for example a full-width **"Call Aung Aung"**, with the rest as secondary pills of at least 48 dp.
- Move Unfriend into the overflow menu, next to Delete.

### C9 · Major · UX — No way to get a card into the phone's contacts or share it
`card_detail_page.dart:434-498`
The only way to share is through QR, and only for `user_card`s. A saved card (the main thing people scan) can't be shared at all, and there's no "Save to Contacts" or vCard export anywhere. Those are the main ways a business card becomes useful after it's scanned.
**Fix:**
- Add **"Save to Contacts"** (generate a vCard locally) and **"Share Card"** (system share sheet) to every card.
- Both need a new package (`share_plus`, or a contacts plugin). Flagged for your approval.

### C10 · Major · UX — Delete and deactivate confirmations don't say what is lost
`card_detail_page.dart:386-402, 481-497`; `cardDetailDeleteCardBody` = "Are you sure you want to delete this card?"
- The delete confirmation doesn't say that the front/back photos and the details are removed for good.
- On your own profile card, the same red "delete" menu slot opens **Deactivate account**. Account deactivation shouldn't sit one tap from a card menu.

**Fix:**
- Name the loss in the dialog: "Delete Aung Aung's card? Its 2 photos and contact details will be removed. This can't be undone."
- Move Deactivate into Settings only.
- Consider undo via a toast in place of the dialog for saved cards.

### C11 · Major · UX — The QR scanner has no states or help
`scan_page.dart:76-127`
- No error or permission-denied state (`MobileScanner` has no `errorBuilder`).
- No hint text ("Point at a businessCard4U QR"), no torch toggle, no way to scan a QR from a gallery image.
- No route to "Show my QR instead", which is the other half of a two-person exchange.

### C12 · Major · UX — The placeholder profile shows a QR that can't work _(verify on device)_
`card_page.dart:1237-1250`, `my_qr_panel.dart:40-42`
If no own card is found, the page creates a fake card with `qrCodeData: 'user-{id}-temp-qr'`, and the QR sheet renders it as a real code. Someone scanning it gets "Card not found".
**Fix:** when `id == 0`, show the existing "Create my profile card" CTA in place of a QR.

### C13 · Major · A11Y — Tap targets well under 48 dp
Search clear button 20 dp (`card_page.dart:1530-1557`), company-pill ✕ about 17 dp (`card_page.dart:297-311`), quick actions 38 dp (`card_detail_page.dart:988`), profession chips 34 dp (`card_page.dart:434`).

### C14 · Minor · UX — Failed launches fail silently
`card_detail_page.dart:27-31`. If no dialer, mail or maps app handles the link, nothing happens. Show a toast and offer "Copy number".

### C15 · Minor · MY — Dates aren't localized
`card_detail_page.dart:957`. `DateFormat('MMM d, yyyy')` has no locale, so Myanmar users see English month names. Pass `Localizations.localeOf(context).toString()`.

### C16 · Minor · TOK — Off-palette reds and greys
`Colors.redAccent` for the bell badge and delete (`card_page.dart:1412`, `card_detail_page.dart:216, 487, 493`), and `Colors.grey[300/600]`, `Colors.black54/38` in the add sheets and empty states. Use `Wallet.danger`, `mutedOf` and `faintOf` instead.

### C17 · Minor · TOK — Sheet geometry drifts
Bottom-sheet radii are 20, 24 and 28, and the QR sheet uses a blue-tinted `#F4F7FB` ground (`card_page.dart:629-631, 644`). The theme's `bottomSheetTheme` already defines these, so drop the per-call overrides.

**Worth keeping:**
- The add-card sheet already makes **scan** the visually dominant path, with manual entry as the fallback (`card_page.dart:715-841`).
- Asking for the back of the card immediately after the front is the right moment.
- Scanned fields get a badge.
- Profession chips are built from real data, with counts.

---

## Cross-cutting

### X1 · Major · MY — No Myanmar font
`app_typography.dart` uses Inter only, and Inter has no Myanmar glyphs, so Myanmar text falls back to each device's system font. Line height and weight differ by device, and Inter's tight `height` values (1.05–1.2) clip stacked Myanmar vowel marks. **Phase 2:** bundle Noto Sans Myanmar, set it as the `fontFamilyFallback` and give Myanmar a line height of at least 1.6.

### X2 · Major · MY/A11Y — The "eyebrow" style breaks Myanmar
`AppTypography.eyebrow` (letter-spacing about 0.09 em, height 1.2) is used at **9–10.5 px** for localized labels:
- the step counter and labels (`onboarding_step_scaffold.dart:220-247`)
- section titles (`OnboardingSection`)
- choice chips
- password strength labels (`complete_register_page.dart:398-405`)
- photo tile labels (`setup_profile_page.dart:704-709, 748-753`)
- detail chips and section labels (`card_detail_page.dart:1030-1036, 1078-1084`)

Letter-spacing separates Myanmar clusters, and 9–10.5 px Myanmar can't be read. `.toUpperCase()` does nothing for Myanmar, so these labels also lose the visual signal they rely on in English.
**Fix:** make the eyebrow locale-aware. For `my`, use no tracking, a 12 px minimum and line height of at least 1.6.

### X3 · Major · A11Y — Almost no screen-reader semantics
There's one `Semantics` widget in all of `lib/ui`. These tappable items have no labels:
- `GestureDetector` photo tiles and avatar pickers (`setup_profile_page.dart:570, 655`; `add_card_page.dart:969`)
- the OTP boxes, which a screen reader announces as six "•"
- the company-filter pill

### X4 · Major · A11Y/MY — Fixed heights around text _(verify at 1.3× text scale)_
Quick actions 38 dp, the chip row 34 dp and the search container 48 dp all hold text in a fixed height. At large text scales, or with Myanmar line heights, labels will clip. Prefer `minHeight` with padding.

### X5 · Major · TOK — Two sources of truth for colour
`AppColors` and `Wallet` define the same accent, ground, ink and line values separately. `card_detail_page.dart:49-73` adds a third layer of aliases (plus an off-system `secondary = #C4B5FD`). **Phase 2:** make `Wallet` the canonical source, turn `AppColors` into thin aliases, and delete the page-local alias layer.

### X6 · Minor · TOK — Raw `TextStyle` bypasses `AppTypography`
`card_page`, `add_card_page`, `card_detail_page` and `otp_page` build raw `TextStyle`s. The font still comes through the `DefaultTextStyle` in `main.dart`, but tracking and the Myanmar fallback from X1 won't apply unless styles go through `AppTypography` or the `textTheme`.

### X7 · Minor · TOK — Empty theme files
`ui/theme/light_theme.dart` and `ui/theme/dark_theme.dart` are 0 bytes. `app_theme.dart` already provides both themes, so these can be deleted.

---

## Hardcoded colour literals (in-scope pages)

| File | `Color(0x…)` literals | Other off-token colours |
|---|---|---|
| `add_card_page.dart` | 23 | `Colors.grey`, `Colors.redAccent` |
| `card_page.dart` | 2 | many `AppColors.primary` (C3), `Colors.grey*`, `Colors.black*` |
| `card_detail_page.dart` | 2 | `Colors.redAccent`, `Colors.black87` |
| `login_page.dart` | 1 | — |
| `register_page.dart` | 1 | — |
| `otp_page.dart` | 1 | `Colors.black.withOpacity` (web), `AppColors.secondary` |
| `scan_page.dart` | 1 | — |

Out of scope, but noted for Phase 2: `deactivate_account_page` 7, `friend_requests_page` 7, `company_detail_page` 6, `company_select_page` 2, `search_page` 1, `settings_page` 1.

---

## Proposals needing backend work (not implemented)

- **P1 — Forgot password.** Add a reset-by-email-OTP flow that reuses the existing OTP screen. Needs a Laravel endpoint.
- **P2 — Value before signup.** Let a new user scan a card, or preview their own card from a photo, before creating an account, then attach it on signup. Needs anonymous or draft card storage.
- **P3 — Permanent QR at registration.** Make sure every account gets a real `qr_code_data` when it's created, so the client never needs the placeholder in C12.

## Architecture note (out of scope)

AGENTS.md lists `goRouter` in the architecture chain, but the app navigates with `Navigator` and `AppPageRoute` through `app_navigator.dart`, and `go_router` isn't used anywhere. Navigation was left alone, as agreed.

---

## Suggested fix order

**Phase 2 — token hardening (all pages)**
1. Make `Wallet` the canonical palette and `AppColors` aliases of it (X5).
2. Replace hardcoded colours, starting with `add_card_page` (C7), the dark-mode accent in `card_page` (C3), and the reds and greys (C16).
3. Add the Myanmar font fallback and a locale-aware eyebrow and line height (X1, X2).
4. Delete the empty theme files (X7).

**Phase 3 — card loop**
1. C1 search auto-clear
2. C2 default tab and empty states
3. C8 detail hierarchy and C13 tap targets
4. C4 and C5 add-card form and discard guard, then C6 company confirmation
5. C11 scanner states and C12 placeholder QR
6. C10 delete copy
7. C9 share and contacts (needs package approval)
8. C14, C15

**Phase 3 — first-run**
1. F1 unified 4-step rail
2. F2 and F3 OTP paste/autofill and resend timing
3. F4 login dark mode and F5 input affordances
4. F6 CTA copy, then F7–F11

---

## Myanmar strings awaiting native review

Drafted alongside Phase 3 changes. Each is live in `lib/l10n/app_my.arb`; replace the value there once reviewed and tick it off here.

| Key | English | Myanmar (draft) | Reviewed |
|---|---|---|---|
| `cardPageEmptySavedTitle` | Your card wallet is empty | သင့်ကတ်အိတ် ဗလာဖြစ်နေပါသည် | ☐ |
| `cardPageEmptySavedSubtitle` | Photograph a business card and we'll fill in the details for you. | စီးပွားရေးကတ်ကို ဓာတ်ပုံရိုက်ပါ၊ အချက်အလက်များကို ကျွန်ုပ်တို့ ဖြည့်ပေးပါမည်။ | ☐ |
| `cardPageEmptySavedScanCta` | Scan Your First Card | ပထမဆုံးကတ်ကို စကင်ဖတ်မည် | ☐ |
| `cardPageEmptyFriendsTitle` | No connections yet | ချိတ်ဆက်မှု မရှိသေးပါ | ☐ |
| `cardPageEmptyFriendsSubtitle` | Let someone scan your QR code to connect, or search for people you know. | ချိတ်ဆက်ရန် သင့် QR ကုဒ်ကို စကင်ဖတ်ခိုင်းပါ၊ သို့မဟုတ် သိသူများကို ရှာဖွေပါ။ | ☐ |
| `cardPageEmptyFriendsQrCta` | Show My QR | ကျွန်ုပ်၏ QR ကို ပြမည် | ☐ |
| `cardPageEmptyFriendsSearchCta` | Find People | လူများ ရှာဖွေမည် | ☐ |
| `cardPageNoMatchingCardsSubtitle` | Nothing on this tab matches your search or filters. | သင့်ရှာဖွေမှု သို့မဟုတ် စစ်ထုတ်မှုနှင့် ကိုက်ညီသော ကတ် မရှိပါ။ | ☐ |
| `cardPageClearFiltersCta` | Clear Filters | စစ်ထုတ်မှုများ ရှင်းမည် | ☐ |
