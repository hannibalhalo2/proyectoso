#!/usr/bin/env bash
REMOTE="35.233.171.84:8090"
TOKEN="aca84fefcb3aad602c52531cca66aff4bf79cc58b1c211d62ee5afd4dc379ddd"
DIGEST="sha256:e1ae8711fa5a7ee30bf577d665a7a91bfe35556f83264c06896765d75b84a990"
UPSTREAM="http://192.168.99.102:31112"
docker run \
--interactive --tty \
--net=host \
--env=REMOTE=${REMOTE} \
--env=TOKEN=${TOKEN} \
inlets/inlets@${DIGEST} \
client \
--remote=${REMOTE} \
--upstream=${UPSTREAM} \
--token=${TOKEN} 
