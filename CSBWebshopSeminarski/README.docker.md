# Docker — pokretanje CSB Webshop API-ja

## Priprema

1. Raspakiraj `.env-tajne.zip` (šifra: **fit**). Ako Windows Explorer javi gresku, koristi 7-Zip ili raspakiraj u `C:\Temp` pa kopiraj `.env`.
2. Postavi `.env` u ovaj folder (gdje je `docker-compose.yml`)

## Pokretanje

```bash
docker compose up -d --build
```

| Servis | URL / port |
|--------|------------|
| API | http://localhost:8080 |
| Swagger | http://localhost:8080/swagger |
| RabbitMQ management | http://localhost:15672 |
| SQL Server | localhost:1433 |

## Baza podataka (automatski)

Pri **prvom** pokretanju (ili nakon `docker compose down -v`) API:

1. čeka da SQL Server bude spreman
2. pokreće EF migracije — kreira bazu `180005` i tabele
3. seeda uloge, admin korisnika i demo podatke

**Admin prijava (seed):** `admin` / `Admin123!`

## Zaustavljanje

```bash
docker compose down
```

Za potpuno čist start (briše bazu):

```bash
docker compose down -v
```
