# PFIA – Pre-Foreclosure Intelligence Agent (MVP)

## Short description
PFIA ingests public lis pendens and related county records, resolves properties and owners, scores leads for near-term foreclosure risk, and exports prioritized leads for investors and agents.

## Quickstart (local dev)
1. Start Postgres/PostGIS with Docker (`db/docker-compose.yml`)
2. Run DDL:
   `psql -h localhost -U pfia -d pfia -f db/ddl.sql`
3. Configure environment:
   copy `.env.example` to `.env` and update `DB_DSN`
4. Run scraper:
   `python etl/lis_pendens_etl.py`
5. Run API:
   `uvicorn api.app:app --reload`
6. Run ML notebook:
   open `ml/scoring_notebook.ipynb`

## Project layout
- `etl/` – scrapers and ingestion scripts
- `api/` – FastAPI backend
- `db/` – DB init, docker-compose, DDL
- `ml/` – model notebooks, training scripts
- `docs/` – design notes, compliance docs

## License
MIT
