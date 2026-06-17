# Docker — pokretanje CSB Webshop API-ja

## Priprema

U folderu gdje je `docker-compose.yml` kreiraj `.env` (vidi `.env.example`):

- `SQL_SA_PASSWORD` — lozinka za SQL Server `sa` korisnika
- `JWT_KEY` — min. 32 znaka (za JWT u Dockeru)
- opciono: `SMTP_*`, `STRIPE_SECRET_KEY`, `RABBITMQ_*`

## Pokretanje

```bash
docker compose up -d --build
```

Servisi:

| Servis | URL / port |
|--------|------------|
| API | http://localhost:8080 |
| RabbitMQ management | http://localhost:15672 |
| SQL Server | localhost:1433 |

## Baza podataka (automatski)

Pri **prvom** pokretanju (ili nakon `docker compose down -v`) API:

1. čeka da SQL Server bude spreman
2. pokreće EF migracije (`Database.Migrate`) — **kreira bazu `180005` i tabele**
3. seeda uloge, admin korisnika i demo podatke

**Admin prijava (seed):**

- korisničko ime: `admin`
- lozinka: `Admin123!` (ili vrijednost iz `AdminSeed:Password` u konfiguraciji)

Ručni restore backupa **nije potreban** za seminarski/demo Docker setup.

### Ako prijava ne radi nakon restarta

1. Provjeri log API-ja: `docker logs ib180005_api --tail 80`
   - trebaš vidjeti `Database migrations applied successfully.`
2. Ako si pokrenula `docker compose down -v`, volumen je obrisan — baza se ponovo kreira pri sljedećem `up` (može trajati ~1 min).
3. Rebuild API-ja nakon promjena koda: `docker compose up -d --build csb_webapi csb_notifications`

## Zaustavljanje

```bash
docker compose down
```

Podaci u bazi **ostaju** (volume `sqlserverdata`).

Za potpuno čist start (briše bazu):

```bash
docker compose down -v
```

Sljedeći `docker compose up` ponovo kreira bazu i seed.
