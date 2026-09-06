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
- Browse/search/edit interface (today's app only quick-adds).
- QR code generation per Box/Item record.
- Label layout for the Avery L7120-25 sheets.
