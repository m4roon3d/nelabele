# NelaBele: notes for Claude

NelaBele shows indicative property rates for Bengaluru Urban and Rural, with guidance values alongside. Owner: Ramanaa
(prefers plain language, short answers). See README.md for the stack and layout.

## Ship

Used by the ship-change skill.

```
target: android-apk + github-pages (build-app.yml on every push to main: APKs to the rolling "app" release,
        web app to https://m4roon3d.github.io/nelabele/)
merge:
  data changes (data/market/published.csv and other data files): direct-to-main
  app or pipeline code: on-"Merge" (squash)
checks: cd app && flutter analyze --no-fatal-infos lib (app changes); python ingest scripts run cleanly (pipeline changes)
release: none
preview: the PR's Build app run uploads nelabele-android and nelabele-web artifacts
after a data push: start the "Load data" workflow
        (gh api -X POST repos/m4roon3d/nelabele/actions/workflows/412178421/dispatches -f ref=main),
        wait for it, and report the "Loaded N published prices" line and any "Not matched" warnings
after a merge: confirm Build app finished; APK link https://github.com/m4roon3d/nelabele/releases/download/app/nelabele.apk
        and the web app link
```

## Rules

- Never delete or overwrite rows in data/market/published.csv; they are the price history.
- Keep secrets (signing password, database credentials) in GitHub secrets only.
