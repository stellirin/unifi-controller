# Supported tags and respective `Dockerfile` links

- [`latest`](https://github.com/stellirin/unifi-controller/blob/master/Dockerfile)
- [`stable, 5.11, 5.11.50`](https://github.com/stellirin/unifi-controller/blob/5.11.50/Dockerfile)

NOTE: `latest` may contain a Release Candidate build. If you wish for stability use a more specific tag!

# Unsupported tags
- [`5.11.39`](https://github.com/stellirin/unifi-controller/blob/5.11.39/Dockerfile)
- [`5.10.27`](https://github.com/stellirin/unifi-controller/blob/5.10.27/Dockerfile)

# Quick reference

-	**Where to get help**:
	[The UniFi Community Forums](https://community.ui.com/)

-	**Where to file issues**:
	[https://github.com/stellirin/unifi-controller/issues](https://github.com/stellirin/unifi-controller/issues)

-	**Maintained by**:
	[Adam Farden](https://github.com/stellirin/unifi-controller)

-	**Supported architectures**:
	`amd64`

# What is the UniFi Network Controller?

The UniFi Network Controller is the front end for the UniFi Software-Defined Networking (SDN) platform, an end-to-end system of network devices across different locations.

![UniFi Logo](https://upload.wikimedia.org/wikipedia/en/9/93/Ubiquiti_Networks_2016.svg)

This project is not an official container image, nor is it associated with Ubiquiti in any way. It was created by reverse engineering the original UniFi scripts.

Motivation for this project comes from the limitations of the source DEB. Specifically, the DEB is restricted to use MongoDB v3.4 because of how the UniFi scripts connect to a locally installed DB. However, UniFi runs perfectly fine on MongoDB v4.0 when connecting to a 'remote' MongoDB installation (i.e. via URI instead of socket).

By default the controller will generate untrusted TLS certificates. This container can also use trusted certificates, for example from Let's Encrypt. The container will also watch any provided certificates for change and trigger a restart.

**\* \* \* NOTE: this project is still a WIP \* \* \***

## **TODO**
- Aarch64 for Raspberry Pi

# How to use this image

This container image must be used in conjunction with an existing MongoDB installation. The simplest method is to use a MongoDB container image.

## Single-node Docker Compose

Use the file from `Appendix A`:
```
docker-compose -f appendix-a.yaml up -d
```

## Multi-node Docker Compose

Use the files from `Appendix A` and `Appendix B`:
```
docker-compose -f appendix-a.yaml -f appendix-b.yaml up -d
```

Initialize the replica set:
```
docker-compose -f appendix-a.yaml -f appendix-b.yaml exec mongo0 mongo
```

Paste in the contents of `Appendix C`.

## Environment Variables

When you start the image, you can adjust the initialization of the instance by passing one or more environment variables.

### `MONGO_DB_HOST`

Host name of the MongoDB installation.

Default value is `localhost`.

### `MONGO_DB_PORT`

Port of the MongoDB installation.

Default value is `27017`.

### `MONGO_DB_USER`

Username for authentication on the MongoDB installation.

No default value.

### `MONGO_DB_PASS`

Password for authentication on the MongoDB installation.

No default value.

### `MONGO_DB_URI`

Full URI for the MongoDB installation. For more complex installations. It can be a single host or multiple hosts in a Replica Set.

Default value will be generated as `mongodb://localhost:27017` unless other MongoDB variables are specified above.

### `MONGO_DB_STAT_URI`

Full URI to the MongoDB stat installation. For more complex installations. It can be a single host or multiple hosts in a Replica Set.

Default is to take the same value as `MONGO_DB_URI`.

### `MONGO_DB_NAME`

The database name on the MongoDB installation.

Default value is `unifi`.

### `UNIFI_HTTPS_PORT`

The port used for the controller UI. By default a container runs without the required privileges to bind to the default HTTPS port. If your container runs with privileges you can change this to use port `443`.

Typically port `443` is achieved at the container platform level (bind external port `443` to internal port `8443`) but this is useful if you are using `--network="host"` and `--cap-add="NET_BIND_SERVICE"`.

Default value is `8443`.

### `UNIFI_TLS_FULLCHAIN`

The path to a full chain certificate that is used for TLS connections to the UI. If no value is supplied then UniFi will generate an untrusted certificate for testing purposes.

No default value.

### `UNIFI_TLS_PRIVKEY`

The path to a private key that is used for TLS connections to the UI. If no value is supplied then UniFi will generate an untrusted certificate for testing purposes.

No default value.

## Advanced Environment Variables

### `JAVA_ENTROPY_GATHER_DEVICE`

Provide an alternative source of randomness. Java will use `/dev/random` on some linux systems, which is a blocking function and may cause slowdowns. A good alternative is to use `/dev/./urandom` which will not block.

No default value.

### `UNIFI_JVM_EXTRA_OPTS`

Provide additional JVM options.

No default value.

# Appendix A: Single-node Docker Compose

```yaml
version: '3.7'

x-mongo-service-template:
  &default-mongo-service
  image: mongo:4.0
  networks:
    - unifi
  restart: always

x-mongo-volume-template:
  &default-mongo-volume
  type: volume
  target: /data/db

networks:
  unifi:
    name: unifi

volumes:
  db0:
    name: unifi_db0
  unifi:
    name: unifi_data

services:
  mongo0:
    << : *default-mongo-service
    volumes:
      - source: db0
        << : *default-mongo-volume

  unifi:
    build: .
    image: "stellirin/unifi-controller:latest"
    hostname: unifi
    depends_on:
      - mongo0
    networks:
      - unifi
    ports:
      - "1900:1900/udp"   # Controller discovery
      - "3478:3478/udp"   # STUN
      - "6789:6789/tcp"   # Speed test
      - "8080:8080/tcp"   # Device/ controller comm.
      - "8443:8443/tcp"   # Controller GUI/API as seen in a web browser
      - "8880:8880/tcp"   # HTTP portal redirection
      - "8843:8843/tcp"   # HTTPS portal redirection
      - "10001:10001/udp" # AP discovery
    restart: always
    volumes:
      - type: volume
        source: unifi
        target: /var/lib/unifi
    environment:
      DB_MONGO_HOST: "mongo0"
```

# Appendix B: Multi-node Docker Compose

```yaml
version: '3.7'

x-mongo-service-template:
  &default-mongo-service
  image: mongo:4.0
  networks:
    - unifi
  restart: always

x-mongo-volume-template:
  &default-mongo-volume
  type: volume
  target: /data/db

x-mongo-etrypoint-template:
  &default-mongo-entrypoint
  entrypoint: [
    "/usr/bin/mongod",
    "--bind_ip_all",
    "--replSet", "unifi"
  ]

volumes:
  db1:
    name: unifi_db1
  db2:
    name: unifi_db2

services:
  mongo0:
    << : *default-mongo-entrypoint

  mongo1:
    << : *default-mongo-service
    << : *default-mongo-entrypoint
    volumes:
      - source: db1
        << : *default-mongo-volume

  mongo2:
    << : *default-mongo-service
    << : *default-mongo-entrypoint
    volumes:
      - source: db2
        << : *default-mongo-volume

  unifi:
    depends_on:
      - mongo0
      - mongo1
      - mongo2
    environment:
      DB_MONGO_URI: "mongodb://mongo0,mongo1,mongo2/unifi?replicaSet=unifi"
```

# Appendix C: MongoDB ReplicaSet

```json
rs.initiate({
    "_id":"unifi",
    "members":[
        { "_id":0, "host":"mongo0:27017" },
        { "_id":1, "host":"mongo1:27017" },
        { "_id":2, "host":"mongo2:27017" }
    ]
})
```