from sqlalchemy import Boolean, Column, Integer, String, Table

from .database import metadata

todos = Table(
    "todos",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("title", String(length=128)),
    Column("completed", Boolean, default=False),
)
