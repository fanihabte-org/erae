compose := "docker compose --env-file .env.ci -f docker-compose.yml -f docker-compose.ci.yml"

defult:
    @just --list

deps:
    {{compose}} run --rm dbt deps

parse:
    {{compose}} run --rm dbt parse

run:
    {{compose}} run --rm dbt run

snapshot:
    {{compose}} run --rm dbt snapshot

build:
    {{compose}} run --rm dbt build

empty:
    {{compose}} run --rm dbt build --empty

down:
    {{compose}} down -v

dbt *ARGS:
    {{compose}} run --rm dbt {{ARGS}}

ci: deps parse run down