LABEL authors="Faniel Habte"

FROM fanihabte/dbt-postgres:1.0.0
COPY . ./erea/

RUN dbt deps

