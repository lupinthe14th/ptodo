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

See: http://localhost:8000/doc

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
