FROM python:3.8-slim-buster AS base-env

WORKDIR /usr/src/app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apt-get update \
  && apt-get -y install netcat gcc postgresql \
  && apt-get clean

COPY ./Pipfile /usr/src/Pipfile
COPY ./Pipfile.lock /usr/src/Pipfile.lock

RUN /usr/local/bin/python -m pip install --upgrade pip \
  ; \
  pip install pipenv --no-cache-dir \
  ; \
  pipenv install --dev --system --deploy && \
  pip uninstall -y pipenv virtualenv-clone virtualenv

COPY . .

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
