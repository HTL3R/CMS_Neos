# Neos 9

Neos publishes no general-purpose image, so this builds `php:8.4-apache` (Neos 9.2 requires PHP 8.4) with the
required extensions and creates a Composer-based Neos project into `./app`.

    docker compose up -d --build
    docker compose logs -f neos   # first boot pulls the Composer project

With `AUTO_SETUP=1` (default) the site installs itself: migrations, admin user,
content repository and the `Neos.Demo` site — no setup wizard to click.

- Frontend: http://localhost:8088
- Backend:  http://localhost:8088/neos — `admin` / `Password1!`
- Adminer:  http://localhost:8188

## Setup wizard instead
Set `AUTO_SETUP=0` in `.env` before the first `up`. The database connection is
still configured from `.env`; finish the rest at http://localhost:8088/setup or
with `docker compose exec neos ./flow setup`.

## Your own site instead of the demo
Set `SITE_PACKAGE=` (empty) before the first `up`, then:

    docker compose exec neos ./flow kickstart:site Vendor.Site
    docker compose exec neos ./flow site:create vendor-site Vendor.Site Vendor.Site:Document.Site

## Common tasks

    docker compose exec neos composer require <vendor/package>
    docker compose exec neos ./flow flow:cache:flush
    docker compose exec neos ./flow user:create <user> <password> <first> <last> --roles Editor

## Notes
- `FLOW_CONTEXT=Development` is set in `docker-compose.yml`.
- DB credentials live in `app/Configuration/Settings.Database.yaml` and are read
  from the container environment, so `.env` stays the single source.
- The project lives in `./app` on the host, so you can edit it with your IDE.
  Flow is file-cache heavy; the first page load after a change is slow on macOS.
- Reset everything: `docker compose down -v && rm -rf app && mkdir app && touch app/.gitkeep`
