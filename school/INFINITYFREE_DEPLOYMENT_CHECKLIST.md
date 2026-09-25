# InfinityFree Deployment Checklist

## Required Files and Folders to Upload

- Laravel application files from this project.
- `app/`
- `bootstrap/`
- `config/`
- `database/` (for application files only; do not run migrations)
- `public/`
- `resources/`
- `routes/`
- `storage/`
- `vendor/`
- `artisan`
- `composer.json`
- `composer.lock`
- `server.php`
- `public/index.php`
- `public/.htaccess`
- The contents of `infinityfree-htdocs.htaccess` copied to the `.htaccess` file located directly in the InfinityFree `htdocs` directory.

## Files and Folders That Must Not Be Uploaded

- `.env` from the local development machine.
- `node_modules/`.
- `.git/`.
- Local database files, database backups, and unrelated SQL exports.
- Development-only files that are not needed by the deployment.
- Any file containing a password, API key, or other private credential.

## InfinityFree MySQL Settings

```dotenv
DB_CONNECTION=mysql
DB_HOST=sql308.infinityfree.com
DB_PORT=3306
DB_DATABASE=if0_42961491_mobischo
DB_USERNAME=if0_42961491
DB_PASSWORD=<ENTER_PASSWORD_PRIVATELY>
```

## Production .env Settings

Create the production `.env` privately on the hosting account. Do not commit it to GitHub.

```dotenv
APP_NAME=Laravel
APP_ENV=production
APP_KEY=<GENERATE_OR_ENTER_PRIVATELY>
APP_DEBUG=false
APP_URL=<YOUR_INFINITYFREE_SITE_URL>

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=sql308.infinityfree.com
DB_PORT=3306
DB_DATABASE=if0_42961491_mobischo
DB_USERNAME=if0_42961491
DB_PASSWORD=<ENTER_PASSWORD_PRIVATELY>

CACHE_DRIVER=file
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
```

Do not replace the local `.env` with these values. Enter the database password privately in the hosting environment only.

## htdocs .htaccess Location

Place the contents of `infinityfree-htdocs.htaccess` in:

```text
<InfinityFree account root>/htdocs/.htaccess
```

The file in `public/.htaccess` is a separate Laravel file and must not be modified.

## Database Import

Import `C:\Users\BHGJJ\Downloads\studmanborromee_infinityfree.sql` through InfinityFree phpMyAdmin before using the application.

Do **not** run Laravel migrations. The test database has already been imported through phpMyAdmin, so the existing tables and data must be preserved.

## Final Checks

- Confirm `public/index.php` and `public/.htaccess` are uploaded.
- Confirm `vendor/autoload.php` is uploaded.
- Confirm `storage/` and `bootstrap/cache/` are writable as required by the host.
- Confirm `APP_DEBUG=false`.
- Confirm `.env` is not tracked or uploaded from local development.
- Do not commit or push deployment credentials.
