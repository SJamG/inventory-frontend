# Garage Inventory App — Handover

## Goal
Self-hosted replacement for LetsTrack QR inventory tags. Physical boxes around the house (garage, loft, office, etc.) get their own QR code label; scanning shows what's inside. No cloud dependency, fully hosted on Jamie's TrueNAS/Dockge homelab under the `sjamg.me` domain.

## Architecture
- **Database/backend:** NocoDB, self-hosted via Docker/Dockge, **Postgres-backed** (not the SQLite default — chosen because NocoDB is intended as a general-purpose DB backend beyond just this app). Live at `https://db.sjamg.me`.
- **Frontend (quick-add app):** a single self-contained `index.html` (vanilla HTML/CSS/JS, no build step, dark/light mode) that talks directly to NocoDB's REST API. Built and tested — works against the live NocoDB instance.
- **Frontend hosting plan:** private GitHub repo (`SJamG` account) → GitHub Actions builds a Docker image on push → pushes to GHCR (`ghcr.io/sjamg/inventory-frontend`) → Dockge pulls that image. Intended URL: `https://box.sjamg.me`.
- **QR codes:** will be printed on Avery L7120-25 laser labels (already purchased). Each label will encode the record's own frontend URL directly — no redirect/interception layer (the original plan reused LetsTrack's `lttag.io/<CODE>` tags via a redirect; that was dropped in favour of printing fresh codes).

## Data model (built and working in NocoDB)
Base name: **Inventory**

- **Boxes** table: Name, Description, Asset Code (auto, formula `CONCAT("BOX-", RECORD_ID())`), Photo (attachment), Room (single select: Garage/Loft/Office, extensible)
  - Table ID: `mpd5wmakym5yo04`
- **Items** table: Name, Description, Asset Code (auto, formula `CONCAT("ITM-", RECORD_ID())`), Photo (attachment), Box (Many-to-One link to Boxes)
  - Table ID: `m83hhqlfdzbozyj`
- Each **physical box = one Boxes record** (not a Homebox-style "Location"); contents go in as linked Items records.

## Decision history worth knowing
- **Homebox** was tried first, rejected: item fields can't be trimmed to just Name/Description/Asset Code/Photo (no field customization, "Hide Empty" toggle doesn't persist across sessions).
- **Snipe-IT** and **InvenTree** ruled out as alternatives: both add more fields/setup steps (IT asset checkout model; Part→StockItem two-step model), not fewer.
- **NocoDB** chosen over **Baserow**: NocoDB's auto-generated REST API better supports building a custom frontend later.
- **Auto Number field type** in NocoDB is paid-tier only — worked around using a **Formula field** with `RECORD_ID()`.
- Had to **delete and recreate** fields when converting Asset Code from text to Formula (NocoDB doesn't allow in-place type conversion once a field has data).
- **Postgres migration hiccups** (both resolved): (1) a password containing `& = # ? /` broke NocoDB's `NC_DB` query-string connection format — fixed with a URL-safe alphanumeric password; (2) after changing the password, the Postgres data directory still had the *old* password baked in and needed to be fully wiped (`rm -rf` on the volume) before the new password would take.

## Subdomains
- `db.sjamg.me` → NocoDB backend/admin — **live and working**
- `box.sjamg.me` → custom frontend — reassigned from an earlier Homebox plan; **not yet deployed/tunnelled**

## Homelab conventions being followed
- PUID=568, PGID=568, TZ=Europe/London on all containers (matches existing sabnzbd/sonarr/radarr/homebox stacks)
- App data at `/mnt/Apps/appdata/<service>/`
- Cloudflare Tunnel + Zero Trust for external access, same pattern as `whisky.sjamg.me` / `fitness.sjamg.me`

## Immediate next steps (not yet done)
1. **Create the private GitHub repo** (`inventory-frontend` suggested name) containing:
   - `index.html` (already built)
   - `Dockerfile` (already drafted — nginx serving the single file)
   - `.github/workflows/build.yml` (already drafted — builds & pushes to GHCR on push to `main`)
2. **Authenticate the TrueNAS Docker host to GHCR** (`docker login ghcr.io -u SJamG` using a GitHub PAT with `read:packages` scope), since the repo/image will be private.
3. **Deploy via Dockge** using the prepared `docker-compose.yml` (pulls `ghcr.io/sjamg/inventory-frontend:latest`, host port `8083` — chosen because `8082` is already used by NocoDB).
4. **Set up the Cloudflare Tunnel ingress rule** for `box.sjamg.me` → the frontend container.

## Work not yet started
- **Browse/search/edit frontend** — the quick-add app only handles adding new records quickly on a phone. A separate (or expanded) interface for browsing, searching, and editing existing Boxes/Items/Rooms is still needed.
- **QR code generation** — need to generate a QR code per Box/Item record encoding its frontend URL (e.g. `https://box.sjamg.me/box/mpd5wmakym5yo04` or similar, exact routing TBD once the browse frontend exists).
- **Printing labels** — once QR generation works, laying them out on the Avery L7120-25 sheets (35×35mm, 875 labels/25 sheets) already purchased.

## Notes on the existing quick-add app (`index.html`)
- Stores NocoDB URL / API token / table IDs in the browser's local storage via an in-app Settings panel (gear icon) — not hardcoded, so it survives config changes without a rebuild.
- Photo capture uses `capture="environment"` to trigger the phone's rear camera directly.
- One known soft spot: the NocoDB **file/attachment upload endpoint** (`/api/v2/storage/upload`) has shifted across NocoDB versions in the past — flagged in a code comment as the most likely place to need adjustment if photo uploads ever misbehave.
