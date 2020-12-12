#!/bin/sh

echo "Waiting for postgres..."
if [ "${DATABASE_URL}" ]; then
  URL=$(echo ${DATABASE_URL} | awk -F[@//] '{print $4}')
  DB_HOST=$(echo ${URL} | awk -F[:] '{print $1}')
  DB_PORT=$(echo ${URL} | awk -F[:] '{print $2}')
fi

echo "Waiting for ${DB_HOST} ${DB_PORT} to be ready"
#while ! nc -z ${DB_HOST} ${DB_PORT}; do
#  echo "Sleep"
#  sleep 0.1
#done

echo "PostgreSQL started"

exec "$@"
