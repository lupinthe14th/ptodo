import logging
import os
from functools import lru_cache

from loguru import logger
from pydantic import AnyUrl, BaseSettings


class Settings(BaseSettings):
    environment: str = os.getenv("ENVIRONMENT", "dev")
    testing: bool = os.getenv("TESTING", 0)
    database_url: AnyUrl = os.environ.get("DATABASE_URL") or '{}://{}:{}@{}:{}/{}'.format(
        os.environ.get("DATABASE"),
        os.environ.get("DB_USERNAME"),
        os.environ.get("DB_PASSWORD"),
        os.environ.get("DB_HOST"),
        os.environ.get("DB_PORT"),
        os.environ.get("DB_NAME"),
    )
    if environment == "dev" or testing == 1:
        logger.debug("logger level: debug")
        logging.basicConfig(level=logging.DEBUG)


@lru_cache()
def get_settings() -> BaseSettings:
    logger.info("Loading config settings from the environment...")
    return Settings()
