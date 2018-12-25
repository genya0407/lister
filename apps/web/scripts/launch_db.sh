docker run --rm -v /var/lib/postgresql/data -e POSTGRES_USER=lister -e POSTGRES_PASSWORD=lister -p 5432:5432 --name lister-postgres -d postgres:11-alpine
