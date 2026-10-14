#!/usr/bin/env bash
set -e
cd /var/www/html

if [ ! -f composer.json ]; then
  echo ">> Creating Neos ${NEOS_VERSION} project..."
  rm -rf /tmp/neos
  composer create-project "neos/neos-base-distribution:${NEOS_VERSION}" /tmp/neos --no-interaction
  cp -a /tmp/neos/. /var/www/html/
  rm -rf /tmp/neos
fi

if [ ! -d Packages/Libraries ]; then
  echo ">> Installing dependencies..."
  composer install --no-interaction
fi

# DB connection is read from the container environment, so .env stays the single source
if [ ! -f Configuration/Settings.Database.yaml ]; then
  cat > Configuration/Settings.Database.yaml <<'YAML'
Neos:
  Flow:
    persistence:
      backendOptions:
        driver: pdo_mysql
        host: '%env:DB_HOST%'
        port: '%env:DB_PORT%'
        dbname: '%env:DB_NAME%'
        user: '%env:DB_USER%'
        password: '%env:DB_PASSWORD%'
        charset: utf8mb4
YAML
fi

if [ ! -f Data/.docker-setup-done ]; then
  if [ "${AUTO_SETUP}" = "1" ]; then
    echo ">> Running non-interactive Neos setup..."
    ./flow doctrine:migrate
    ./flow user:create "${ADMIN_USER}" "${ADMIN_PASSWORD}" "${ADMIN_FIRSTNAME}" "${ADMIN_LASTNAME}" --roles Administrator
    ./flow cr:setup --content-repository default
    if [ -n "${SITE_PACKAGE}" ]; then
      ./flow site:importall --package-key "${SITE_PACKAGE}"
    fi
    ./flow resource:publish
    mkdir -p Data && touch Data/.docker-setup-done
  else
    echo ">> Skipping auto setup — finish it at /setup or with ./flow setup."
  fi
fi

chown -R www-data:www-data /var/www/html
exec "$@"
