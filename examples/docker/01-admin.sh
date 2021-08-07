#!/bin/bash

create_user() {
    mongo admin \
        --host localhost \
        --eval "db.createUser($1);"
}

create_user "{
    user: '${MONGO_DB_USER}',
    pwd:  '${MONGO_DB_PASS}',
    roles: [
        {
            role: 'readWrite',
            db:   '${MONGO_INITDB_DATABASE}'
        },
        {
            role: 'readWrite',
            db:   '${MONGO_INITDB_DATABASE}_stat'
        }
    ]
}"
