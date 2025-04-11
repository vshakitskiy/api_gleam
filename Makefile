db_up:
	docker compose up db redis

db_down:
	docker compose down db redis

migrate_up:
	gleam run migrate up

migrate_down:
	gleam run migrate down

run:
	gleam run migrate up && \
	gleam run dev