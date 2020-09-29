from fastapi import APIRouter, HTTPException, status
from typing import List

from loguru import logger
from .. import schemas, crud

router = APIRouter()


@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    response_model=schemas.Todo,
)
async def create_todo(payload: schemas.TodoCreate):
    todo_id = await crud.create(payload)
    return {**payload.dict(), "id": todo_id}


@router.get("/", response_model=List[schemas.Todo])
async def read_todos():
    rows = await crud.read()
    if rows is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="todo's not found"
        )
    return rows


@router.get("/{todo_id}", response_model=schemas.Todo)
async def read_todo(todo_id: int):
    row = await crud.read_by_id(todo_id)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="todo not found"
        )
    return row


@router.put("/", response_model=schemas.Todo)
async def update_todo(payload: schemas.TodoUpdate):
    row = await crud.update(payload)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="todo not found"
        )
    return row


@router.delete("/{todo_id}")
async def delete_todo(todo_id: int):
    row = await crud.delete_by_id(todo_id)
    logger.debug("row: {}".format(row))
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="todo not found"
        )
    return {"result": "delete success"}
