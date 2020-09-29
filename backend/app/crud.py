from typing import Union

from loguru import logger
from sqlalchemy.dialects import postgresql

from .database import database
from .models import todos
from .schemas import TodoCreate, TodoUpdate


@database.transaction()
async def create(payload: TodoCreate) -> Union[int, None]:
    logger.debug("payload: {}".format(payload))
    stmt = todos.insert().values(title=payload.title, completed=payload.completed)
    logger.debug(
        "stmt: {}".format(
            stmt.compile(
                dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}
            )
        )
    )
    id = await database.execute(stmt)
    logger.debug("id: {}".format(id))
    if not id:
        return None
    return id


async def read() -> Union[dict, None]:
    stmt = todos.select()
    logger.debug(
        "stmt: {}".format(
            stmt.compile(
                dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}
            )
        )
    )
    rows = await database.fetch_all(stmt)
    if not rows:
        return None
    return rows


async def read_by_id(todo_id: int) -> Union[dict, None]:
    stmt = todos.select(todos.columns.id == todo_id)
    logger.debug(
        "stmt: {}".format(
            stmt.compile(
                dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}
            )
        )
    )
    row = await database.fetch_one(stmt)
    if not row:
        return None
    return row


@database.transaction()
async def update(payload: TodoUpdate) -> Union[dict, None]:
    row = await read_by_id(payload.id)
    if not row:
        return None

    stmt = (
        todos.update()
        .where(todos.columns.id == payload.id)
        .values(title=payload.title, completed=payload.completed)
    )
    logger.debug(
        "stmt: {}".format(
            stmt.compile(
                dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}
            )
        )
    )
    await database.execute(stmt)
    return payload


@database.transaction()
async def delete_by_id(todo_id: int) -> Union[int, None]:
    row = await read_by_id(todo_id)
    logger.debug("row: {}".format(row))
    if not row:
        return None

    stmt = todos.delete().where(todos.columns.id == todo_id)
    logger.debug(
        "stmt: {}".format(
            stmt.compile(
                dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}
            )
        )
    )
    await database.execute(stmt)
    return todo_id
