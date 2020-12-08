from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from .config import get_settings
from .database import database, engine
from .models import metadata
from .routers import todos, root

metadata.create_all(bind=engine)


async def get_token_header(x_token: str = Header(...)):
    if x_token != "fake-super-secret-token":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Token header invalid",
        )


def create_application() -> FastAPI:
    application = FastAPI()

    origins = [
        "http://api:8000",
        "http://localhost:8000",
        "http://localhost:3000",
    ]

    application.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    application.include_router(
        todos.router,
        prefix="/todos",
        tags=["todos"],
        dependencies=[Depends(get_token_header), Depends(get_settings)],
        responses={404: {"description": "Not found"}},
    )

    application.include_router(
        root.router,
        tags=["root"],
        dependencies=[Depends(get_settings)],
        responses={404: {"description": "Not found"}},
    )

    return application


app = create_application()


@app.on_event("startup")
async def startup():
    logger.info("Starting up...")
    await database.connect()


@app.on_event("shutdown")
async def shutdown():
    logger.info("Shutting down...")
    await database.disconnect()
