#!/bin/sh
set -e

# Run database migrations
echo "Running database migrations..."
bundle exec rake db:migrate

# Then exec the container's main process (what's set as CMD in the Dockerfile)
exec "$@"