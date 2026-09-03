FROM fanihabte/base-dbt-postgres:1.0.1
LABEL authors="Faniel Habte"

WORKDIR /erae

COPY . .

RUN dbt deps

