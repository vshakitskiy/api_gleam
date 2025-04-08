db_up:
	docker compose up

db_down:
	docker compose down

migrate_up:
	gleam run migrate up

migrate_down:
	gleam run migrate down

run:
	gleam run dev