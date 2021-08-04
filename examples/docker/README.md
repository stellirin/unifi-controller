# UniFi Controller on Docker

Add the relevant environment variables to a '`.env`' file in this folder to customize the Docker Compose behaviour.

## Launch

```
docker-compose up -d
```

## Backup

The Docker volumes can be backed up with:

```sh
docker run \
     --rm \
     --volume=unifi-controller:/volume:ro \
     --volume=${PWD}:/backup:rw \
    alpine \
    tar -czf /backup/controller-$(date '+%Y-%m-%d').tar.gz -C /volume ./

docker run \
     --rm \
     --volume=unifi-mongodb:/volume:ro \
     --volume=${PWD}:/backup:rw \
    alpine \
    tar -czf /backup/mongodb-$(date '+%Y-%m-%d').tar.gz -C /volume ./
```

## Restore

The last volume backups can be restored with:

```sh
docker run \
     --rm \
     --volume=${PWD}:/backup:ro \
     --volume=unifi-controller:/volume:rw \
    alpine \
    tar -C /volume/ -xzf /backup/$(ls -1 | grep 'controller-.*.tar.gz' | tail -1)

docker run \
     --rm \
     --volume=${PWD}:/backup:ro \
     --volume=unifi-mongodb:/volume:rw \
    alpine \
    tar -C /volume/ -xzf /backup/$(ls -1 | grep 'mongodb-.*.tar.gz' | tail -1)
```
