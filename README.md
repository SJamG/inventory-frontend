# Inventory Frontend

Self-contained quick-add frontend for the home inventory system (Boxes/Items
backed by NocoDB). See `inventory-app-handover.md` for the full project
history and architecture notes.

## What's here
- `index.html` — the app itself (vanilla HTML/CSS/JS, no build step). Talks
  directly to the NocoDB REST API. Connection settings (NocoDB URL, API
  token, table IDs) are entered once via the in-app Settings panel (gear
  icon) and stored in the browser's local storage — nothing is hardcoded
  except the non-secret defaults (NocoDB URL and table IDs), which are
  pre-filled so you only need to paste in your API token on first load.
- `Dockerfile` — serves `index.html` via nginx.
- `docker-compose.yml` — stack definition for Dockge.
- `.github/workflows/build.yml` — builds and pushes the image to GHCR on
  every push to `main`.

## QR codes & the detail view

Every Box/Item row (and the add/edit sheet) has a QR button. It links to a
read-only detail page baked into the same `index.html` — no separate app or
routing setup needed:
- `https://box.sjamg.me/?view=box&id=<Id>` shows a Box's name, room, photo,
  description, and everything currently linked to it as an Item.
- `https://box.sjamg.me/?view=item&id=<Id>` shows an Item and which Box it's in.

**Important:** the NocoDB URL/token/table IDs live in each browser's local
storage, not on the server. If someone scans a label on a phone that has
never opened the app before, the detail page will prompt them to open
Settings and connect before it can show anything. On a device you've
already configured, scanning "just works".

## Printing labels

Settings → **Print QR Labels…** (or `?view=print&type=boxes` /
`&type=items`) opens an on-screen tool for the Avery L7120-25 sheet
(nominally 35×35mm, 35 per A4 sheet). Exact margins vary by printer, so:
1. Tick **Calibration mode** and print a test sheet on plain paper — it
   prints outlines only, no ink wasted on real QR codes.
2. Hold the test sheet up to a real label sheet against a light source and
   nudge the column/row/pitch/margin numbers (in mm) until the outlines
   line up.
3. Untick calibration mode and print for real. The numbers you dialled in
   are remembered (per browser) for next time.

## Deploying

1. **Push to GitHub** — this repo should live at `github.com/SJamG/inventory-frontend`
   (private). The included workflow uses the repo's own `GITHUB_TOKEN`, so
   no extra secrets are needed for the build/push step itself.

2. **Authenticate your TrueNAS Docker host to GHCR** (needed because the
   image is private):
   ```
   docker login ghcr.io -u SJamG
   ```
   Use a GitHub Personal Access Token (classic, `read:packages` scope) as
   the password.

3. **Deploy via Dockge** — paste `docker-compose.yml` into a new stack and
   start it. It publishes on host port `8083`.

4. **Cloudflare Tunnel** — add an ingress rule for `box.sjamg.me` pointing
   at the `inventory-frontend` container on port `80`, same pattern as
   `whisky.sjamg.me` / `fitness.sjamg.me`.

5. **First run** — open `https://box.sjamg.me`, tap the gear icon, and
   enter your NocoDB API token (URL and table IDs are already filled in).

## Still to do
- Richer browse/edit UI (a visual redesign is in progress — see chat/PR history).
- Fine-tune the label print calibration against the actual Avery sheets once printed.
