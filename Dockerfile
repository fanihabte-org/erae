FROM fanihabte/base-dbt-postgres:1.0.1
LABEL authors="Faniel Habte"

WORKDIR /erae

COPY . .

# Run dbt deps during build stage
RUN dbt deps

ENTRYPOINT ["dbt"]
CMD ["run"]