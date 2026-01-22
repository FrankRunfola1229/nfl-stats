# nfl-stats

A small Node/Express + EJS app that serves simple NFL stat pages (passing/receiving/rushing) from static JSON files and renders charts in the browser.

> **Security note:** this repo originally contained a `variables.env.example` file with real credentials. In this packaged zip, those values have been **removed** and replaced with a template (`variables.env.example.example`). Do **not** commit real secrets.

## Quick start

### Prereqs
- Node.js 18+ (works on 20+ too)
- npm (ships with Node)

### Run locally
```bash
# 1) install deps
npm install

# 2) start server
npm start

# 3) open
# http://localhost:3000
```

### Useful routes
- `/` — home
- `/sports` — sports landing
- `/sports/passing`
- `/sports/receiving`
- `/sports/rushing`
- `/movies` and `/tools` exist as extra sections (optional / older content)

## Project structure

```text
nfl-stats/                               # project root
|
├── app.js                               # Express app entrypoint (registers routes, starts server)
├── package.json                         # npm scripts + dependencies
├── variables.env.example                # environment variable template (copy to variables.env locally)
├── Makefile                             # shortcut commands (install/start/dev/clean)
├── create.sql                           # optional DB schema script (if you wire up a DB later)
├── .gitignore                           # git ignore rules (keeps secrets + build artifacts out of commits)
├── .vscode/                             # editor settings (optional)
│   └── settings.json                    # VS Code workspace settings
|
├── data/                                # static JSON datasets used by the sports pages
│   ├── PassingData.json                 # passing stats sample data
│   ├── ReceivingData.json               # receiving stats sample data
│   └── RushingData.json                 # rushing stats sample data
|
├── public/                              # static assets served by Express
│   ├── images/                          # image assets (png/jpg files omitted from this tree)
│   ├── stylesheets/                     # CSS styles (css files omitted from this tree)
│   └── scripts/                         # browser-side JS (charts/page behavior)
│       ├── passing.js                   # passing page client logic
│       ├── receiving.js                 # receiving page client logic
│       ├── rushing.js                   # rushing page client logic
│       └── movies.js                    # movies page client logic (legacy/extra section)
|
├── routes/                              # Express route modules
│   ├── index.js                         # home route (/)
│   ├── sports.js                        # sports routes (/sports/*)
│   ├── movies.js                        # movies routes (/movies)
│   └── tools.js                         # tools routes (/tools)
|
└── views/                               # EJS templates (server-rendered HTML)
    ├── layouts/                         # layout wrappers
    │   └── boilerplate.ejs              # base layout used by pages
    |
    ├── partials/                        # shared HTML partials
    │   ├── head.ejs                     # <head> tags + includes
    │   ├── nav.ejs                      # top navigation
    │   └── footer.ejs                   # footer
    |
    ├── sports/                          # sports page templates
    │   ├── index.ejs                    # sports landing page
    │   ├── passing.ejs                  # passing stats page
    │   ├── receiving.ejs                # receiving stats page
    │   ├── rushing.ejs                  # rushing stats page
    │   └── defense.ejs                  # defense page (if wired to data later)
    |
    ├── index.ejs                        # home page template
    ├── movies.ejs                       # movies page template (legacy/extra section)
    └── tools.ejs                        # tools page template (legacy/extra section)
```

### What lives where
- **app.js** — Express app entrypoint (listens on port **3000**).
- **routes/** — route handlers (`/`, `/movies`, `/sports`, `/tools`).
- **views/** — EJS templates (layout + partials + page templates).
- **public/** — static assets (CSS, images, front-end JS).
- **data/** — static JSON used by the sports pages.
- **create.sql** — optional SQL Server script (ultra-simple 3NF NFL schema + sample queries).

## Commands

This repo keeps it simple:

```bash
npm start        # runs: node app.js
```

If you want auto-reload while developing:

```bash
npx nodemon app.js
```

## Makefile (optional helper)

If you're on macOS/Linux/WSL you can use:

```bash
make install
make start
make dev
```

Run `make help` to see targets.

## Environment variables / secrets

If you need to use environment variables, follow this approach:

1. Copy the template:
   ```bash
   cp variables.env.example.example variables.env.example
   ```
2. Put real values in `variables.env.example`
3. **Never** commit it (already added to `.gitignore`)

If you later wire dotenv into the app, the conventional name is `.env`.

## Notes / next improvements (practical)
- Add a `dev` script in `package.json` (so you can run `npm run dev`).
- Add a small data validation step (schema check for the JSON files).
- Remove unused dependencies from `package.json` to speed installs.
- Add a basic test (even one route test) so CI can fail fast.


## Using This Project in WSL (Windows Subsystem for Linux)

This project is **WSL-friendly** and intended to be run inside a Linux environment for consistency with production-like workflows.

### Prerequisites
- WSL2 installed
- Ubuntu 22.04+ recommended
- Node.js 18+
- npm

### Recommended Setup
```bash
# From Windows PowerShell (one time)
wsl --install

# Inside WSL
sudo apt update && sudo apt upgrade -y
sudo apt install -y nodejs npm make
```

### Clone and Run (WSL)
```bash
cd ~
git clone <your-repo-url>
cd nfl-stats
make install
make start
```

### Why WSL?
- Matches Linux-based CI/CD runners
- Avoids Windows filesystem edge cases
- Faster I/O than mounted drives when run inside WSL (`/home/...`)

**Tip:** Keep the project inside your WSL home directory, not `/mnt/c/`, for best performance.
