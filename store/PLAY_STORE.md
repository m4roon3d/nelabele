# Putting NelaBele on Google Play

Everything the listing needs is in this folder or built by CI. The steps marked **You** need your Google account.

## What's ready

| Item | Where |
|---|---|
| App bundle (.aab), signed with the NelaBele key | `nelabele.aab` on the "app" release: https://github.com/m4roon3d/nelabele/releases/download/app/nelabele.aab |
| Privacy policy | https://m4roon3d.github.io/nelabele/privacy.html (source: `store/privacy.html`) |
| Listing text, English and Kannada | `store/listing.md` |
| Icon 512×512, feature graphic 1024×500, 7 phone screenshots | "Store screenshots" workflow artifact `store-screenshots` |
| Package name | `app.nelabele.nelabele` (permanent once uploaded) |

## Steps

1. **You: create the developer account** at https://play.google.com/console/signup. Pay the one-off US$25 and verify
   your identity. A personal account is fine.
2. **You: create the app.** Play Console → Create app. Name "NelaBele: Bengaluru land rates", default language
   English (India) – en-IN, App, Free. Accept the declarations.
3. **Set up the app** (Dashboard → "Set up your app"); answers below.
4. **Store listing:** paste from `listing.md`, upload the icon, feature graphic and 2–8 phone screenshots.
5. **Testing → Closed testing:** create a track, add at least 12 testers by email (a Google Group works), upload
   `nelabele.aab`, roll out. Keep Play App Signing on (the default): Google holds the key phones see, and our key
   is the upload key.
6. **Wait 14 days.** New personal accounts must keep 12 testers opted in for 14 days in a row before Play allows a
   production release. Testers install from the opt-in link Play gives you.
7. **Dashboard → Apply for production**, answer the short questions about the test, then release to production.
   Review usually takes a few days.

Every later version: CI builds a new `nelabele.aab` on each merge; upload it to the track you're using.

## Answers for "Set up your app"

- **App access:** All functionality is available without special access. (The editor key only adds rate logging
  for the owner; reviewers don't need it.)
- **Ads:** No ads.
- **Content rating:** questionnaire category "Reference, News, or Educational"; answer No to every content
  question. Expected rating: Everyone / 3+.
- **Target audience:** 18 and over.
- **News app:** No.
- **Government app:** No. (It shows public government data but isn't made by the government; say so in the
  description if asked.)
- **Financial features:** none of the listed ones. The loan calculator is a calculator only; it doesn't offer or
  arrange loans.
- **Health:** No.
- **Data safety:**
  - Does the app collect or share user data? **Yes** (location is sent to find nearby places).
  - Encrypted in transit: **Yes**. Users can request deletion: not applicable (nothing is stored).
  - Data types: **Location → Approximate and Precise location**: Collected, not shared; processed ephemerally
    (not stored); optional (only when the user taps "Places near me"); purpose: App functionality.
  - Photos, notes and contacts that users add stay on the device and are never sent, so they are **not** collected.
  - No account, no personal info, no analytics, no device IDs.
- **Privacy policy URL:** https://m4roon3d.github.io/nelabele/privacy.html

## Good to know

- A personal account shows your name as the developer on the listing. An organisation account (needs a free
  D-U-N-S number) shows a company name and skips the 12-tester rule.
- The APK download link keeps working alongside Play, but Play builds and APK builds are signed differently
  by the time they reach phones: switching between them needs an uninstall (saved places and notes are lost).
