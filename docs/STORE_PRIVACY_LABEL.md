# App Store Connect — Privacy Nutrition Label answers (v1)

Paste-ready answers for the App Store Connect **App Privacy** questionnaire.
Rationale: v1 is free, SDK-free, makes no network requests, and persists all
state on-device only (see `docs/PROJECT_BRIEF.md` monetization line + ADR-0002).

## Top-level question

> Do you or your third-party partners collect data from this app?

**No — "Data Not Collected."**

Selecting this answers the entire questionnaire: no data types, no purposes, no
tracking. ASC will display **"Data Not Collected"** on the product page.

## Why each category is "not collected"

| Category | Collected? | Reason |
|---|---|---|
| Contact Info | No | No account / no sign-in |
| Health & Fitness | No | N/A |
| Financial Info | No | No purchases, no ads |
| Location | No | No location APIs used |
| Sensitive Info | No | N/A |
| Contacts | No | No Contacts access |
| User Content | No | Gameplay state stays on-device, never transmitted |
| Browsing History | No | No web/network activity |
| Search History | No | N/A |
| Identifiers | No | No user/device IDs, no IDFA, no SDKs |
| Purchases | No | No IAP in v1 |
| Usage Data | No | No analytics SDK |
| Diagnostics | No | No crash/analytics SDK |
| Other Data | No | — |

## Tracking

**App does not track** (no ATT prompt needed — nothing is shared with third
parties for tracking, no advertising identifiers).

## Privacy Policy URL

App Store requires a reachable, human-readable URL. The repo is **public**, so
the rendered policy is live at:

    https://github.com/tomzohar/ball-sort-game/blob/main/docs/PRIVACY.md

Use that as the App Store privacy-policy URL. (If a cleaner branded page is wanted
later, enable GitHub Pages and point it at `docs/PRIVACY.md` — optional, not a
blocker.) Confirm the link resolves before submission.

## Revisit-before-each-release checklist

If any of these change, this label and `docs/PRIVACY.md` must be updated **before**
that build ships:

- [ ] Any analytics / crash-reporting SDK added
- [ ] Any ads or ad SDK added
- [ ] Any account, login, or cloud sync added
- [ ] Any network request introduced (incl. Game Center — see note below)
- [ ] Any In-App Purchase added

> **Game Center note (E10):** Game Center itself is Apple-operated and does not by
> itself flip this to "Data Collected," but adding it introduces network activity
> and an Apple-side identifier. Re-review this label when E10 lands.
