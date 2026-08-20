LABEL authors="Faniel Habte"

FROM fanihabte/dbt-postgres:1.0.0
COPY dbt_project.yml package.yml package-lock.yml ./

RUN dbt deps
COPY . .
