import os

from databases import Database
from sqlalchemy import MetaData, create_engine

SQLALCHEMY_DATABASE_URL = (
    os.environ.get("DATABASE_URL")
    or "postgresql://dev:password-dev@localhost/ptodo_dev"
)

database = Database(
    SQLALCHEMY_DATABASE_URL,
    ssl=False,
    min_size=5,
    max_size=20,
)

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    echo=False,
)

metadata = MetaData()
