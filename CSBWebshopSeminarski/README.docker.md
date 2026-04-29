Building and running your application
Before starting, create a `.env` file in the same folder as `docker-compose.yml` and define:
- `SQL_SA_PASSWORD`
- `SMTP_SERVER`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`

When you're ready, start your application by running from the root folder where `docker-compose.yml` file is located:
`docker compose up --build`

Your application will be available at http://localhost:8080.

After running the `docker compose up` command, connect to SQL Server via SSMS and restore your backup.

First create backup folder in the SQL Server container:
`docker exec -it ib180005_sqlserver mkdir -p /var/opt/mssql/backup`

Then copy the backup file to the created folder:
`docker cp /your-local/path/backup_file ib180005_sqlserver:/var/opt/mssql/backup/`

After the backup is copied, restore it via SSMS.

Deploying your application to the cloud
First, build your image, e.g.: docker build -t myapp .. If your cloud uses a different CPU architecture than your development machine (e.g., you are on a Mac M1 and your cloud provider is amd64), you'll want to build the image for that platform, e.g.: docker build --platform=linux/amd64 -t myapp ..

Then, push it to your registry, e.g. docker push myregistry.com/myapp.

Consult Docker's getting started docs for more detail on building and pushing.

References
Docker's .NET guide
The dotnet-docker repository has many relevant samples and docs.