db_up:
	docker compose up db

db_down:
	docker compose down db

migrate_up:
	gleam run migrate up

migrate_down:
	gleam run migrate down

run:
	gleam run dev