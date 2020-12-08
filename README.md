# ptodo

## これは何？
- Python, Vue.js, RDBを利用したTODOアプリ

## 機能
- TODOリスト表示機能
- TODOリストへのTODO追加/削除機能

## For Development

### Requestment

- docker
- docker-compose

### App Overview

#### frontend
- [nodejs](https://nodejs.org/)
- [Vue.js](https://v3.vuejs.org)
- [vite](https://github.com/vitejs/vite)
- [axios](https://github.com/axios/axios)

#### backend
- [Python](https://www.python.org)
- [FastAPI](https://fastapi.tiangolo.com/)
- [SQLAlchemy](https://docs.sqlalchemy.org/)
- [databases](https://www.encode.io/databases/)
- [Starlette](https://www.starlette.io)

#### db
- PostgreSQL10.7

### Deploy and Run

git clone:

```
git clone https://github.com/lupinthe14th/ptodo
```

build & Run the container:

```
cd ptodo
docker-compose up -d --build
```

See: http://localhost:3000


### Swagger API document

See: http://localhost:8000/docs

### Other Commands

#### Common

To stop the containers:

```
docker-compose stop
```

To bring down the containers and remove images:

```
docker-compose down --rmi all
```

Watch logs:

```
docker-compose logs -f
```

#### frontend

TBD

#### backend


Lint:

```
docker-compose exec api flake8 
```

Run Black and isort with check options:

```
docker-compose exec api black . --check
docker-compose exec api /bin/sh -c "isort ./**/*.py --check-only"
```

Make code changes with Black and isort:

```
docker-compose exec api black .
docker-compose exec api /bin/sh -c "isort ./**/*.py"
```


#### db

Postgres:

```
docker-compose exec db psql -U postgres
```


## SeeAlso
- [TodoMVC](http://todomvc.com/examples/vue/)
- [tiangolo/full-stack-fastapi-postgresql](https://github.com/tiangolo/full-stack-fastapi-postgresql) 


## CI/CD

using [terraform](https://www.terraform.io/)

## Manage tfstate file

seeAlso: https://www.terraform.io/docs/backends/types/s3.html

The tfstate files are managed using S3 buckets.

- enable versionning
- configure encryption
- configure block public access

```
aws s3api create-bucket --bucket tfstate-ptodo-prod \
  --create-bucket-configuration LocationConstraint=ap-northeast-1
```

```
aws s3api put-bucket-versioning --bucket tfstate-ptodo-prod \
  --versioning-configuration Status=Enabled
```

```
aws s3api put-bucket-encryption --bucket tfstate-ptodo-prod \
  --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'
```

```
aws s3api put-public-access-block --bucket tfstate-ptodo-prod \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
}'
```

