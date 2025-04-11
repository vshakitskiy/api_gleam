db_up:
	docker compose up db

db_down:
	docker compose down db

migrate_down:
	gleam run migrate down

run:
	gleam run migrate up && \
	gleam run dev