from pydantic import BaseModel


class TodoUpdate(BaseModel):
    id: int
    title: str
    completed: bool


class TodoCreate(BaseModel):
    title: str
    completed: bool = False


class Todo(BaseModel):
    id: int
    title: str
    completed: bool
