# Inventory Frontend

Self-contained quick-add frontend for the home inventory system (Boxes/Items
backed by NocoDB). See `inventory-app-handover.md` for the full project
history and architecture notes.

## What's here
- `index.html` — the app itself (vanilla HTML/CSS/JS, no build step). Talks
  directly to the NocoDB REST API. Every device auto-configures itself from
  `config.js` (see below) — no manual setup needed. The in-app Settings
  panel (gear icon) still exists as a per-device override, saved to that
  browser's local storage, in case you ever want one device to point
  somewhere different.
- `Dockerfile` — serves `index.html` via nginx and bakes in `config.js.template`
  plus the startup script that renders it.
- `config.js.template` — a template for `window.SERVER_CONFIG`, filled in at
  container startup from environment variables.
- `40-inject-config.sh` — nginx startup hook (`/docker-entrypoint.d/`) that
  runs `envsubst` on the template to produce the real `config.js` before
  nginx starts serving.
- `docker-compose.yml` — stack definition for Dockge, including the
  `NOCODB_*` environment variables that drive auto-config.
- `.github/workflows/build.yml` — builds and pushes the image to GHCR on
  every push to `main`.

## Auto-config (every device connects automatically)

The container is given your NocoDB URL, API token, and table IDs once, as
environment variables in Dockge. At startup, nginx renders those into a
small `config.js` file that `index.html` loads before anything else runs.
That means **any** device that opens `https://box.sjamg.me` — your wife's
phone, a brand-new browser, a private/incognito window — is instantly
connected, with nothing to type in and nothing lost when a private window
closes. This is what makes "scan a QR code, see what's in the box" actually
work for someone other than you.

Set these in Dockge's environment editor for the `inventory-frontend`
stack (the `docker-compose.yml` in this repo only ever contains a
placeholder for the token — never commit your real one to git):
- `NOCODB_URL` — e.g. `https://db.sjamg.me`
- `NOCODB_TOKEN` — your real NocoDB API token (secret — Dockge only)
- `NOCODB_BOXES_ID` — the Boxes table ID
- `NOCODB_ITEMS_ID` — the Items table ID
- `NOCODB_LINK_FIELD` — the Items→Boxes link field name (`Box`)

The in-app Settings panel still works exactly as before and takes priority
on whichever single device you use it on — handy if you ever want to point
one device (e.g. a test browser) at a different NocoDB instance without
touching the shared config.

## QR codes & the detail view

Every Box/Item row (and the add/edit sheet) has a QR button. It links to a
read-only detail page baked into the same `index.html` — no separate app or
routing setup needed:
- `https://box.sjamg.me/?view=box&id=<Id>` shows a Box's name, room, photo,
  description, and everything currently linked to it as an Item.
- `https://box.sjamg.me/?view=item&id=<Id>` shows an Item and which Box it's in.

Thanks to auto-config (above), scanning a label "just works" on any device —
no Settings step required.

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

3. **Deploy via Dockge** — paste `docker-compose.yml` into a new stack, fill
   in the real `NOCODB_TOKEN` (and adjust the other `NOCODB_*` vars if
   needed) in Dockge's own environment editor, and start it. It publishes
   on host port `8083`.

4. **Cloudflare Tunnel** — add an ingress rule for `box.sjamg.me` pointing
   at the `inventory-frontend` container on port `80`, same pattern as
   `whisky.sjamg.me` / `fitness.sjamg.me`.

5. **First run** — open `https://box.sjamg.me` on any device. It's already
   connected — no setup step.

6. **Updating an existing stack** — if you deployed before auto-config
   existed, pull the latest image in Dockge, then add the `NOCODB_*`
   environment variables to the stack (with your real token) and restart
   the container so the startup script can render `config.js`.

## Still to do
- Richer browse/edit UI (a visual redesign is in progress — see chat/PR history).
- Fine-tune the label print calibration against the actual Avery sheets once printed.
