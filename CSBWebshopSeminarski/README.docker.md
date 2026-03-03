# Docker - Coco Sun Bags Webshop

## Building and running your application

When you're ready, start your application by running from the root folder where `docker-compose.yml` file is located:

```bash
docker compose up --build
```

Your application will be available at **http://localhost:8080**.

## SQL Server setup

After running the `docker compose up` command, connect to SQL Server via SSMS and add the backup to the server to be able to restore it.

1. **Create backup folder in the SQL Server container:**
   ```bash
   docker exec -it csb_sqlserver mkdir -p /var/opt/mssql/backup
   ```

2. **Copy the backup file to the created folder:**
   ```bash
   docker cp /your-local/path/backup_file.bak csb_sqlserver:/var/opt/mssql/backup/
   ```

3. **Restore** the backup via SSMS (SQL Server Management Studio).

   - Server: `localhost,1433` (or `127.0.0.1,1433`)
   - Login: `sa` / Password: `CocoSunBags2025!`

## Services

| Service | URL | Description |
|---------|-----|-------------|
| API | http://localhost:8080 | Web API aplikacija |
| RabbitMQ Management | http://localhost:15672 | RabbitMQ dashboard (webshop/webshop123) |
| SQL Server | localhost:1433 | SQL Server baza podataka |

## Deploying your application to the cloud

1. **Build the image:**
   ```bash
   docker build -t myapp .
   ```

2. **For different CPU architecture** (e.g. Mac M1 → cloud amd64):
   ```bash
   docker build --platform=linux/amd64 -t myapp .
   ```

3. **Push to your registry:**
   ```bash
   docker push myregistry.com/myapp
   ```

Consult Docker's [getting started docs](https://docs.docker.com/get-started/) for more detail on building and pushing.

## References

- [Docker's .NET guide](https://docs.docker.com/language/dotnet/)
- [The dotnet-docker repository](https://github.com/dotnet/dotnet-docker) - samples and docs
