# Varnish 4 with Docker

This image is intended to provide a caching and load balancing layer in front of web containers.

## Start the container

```bash
$ docker run -d -P \
--link container_name:node1 \
--link container_name2:node2 \
creativearea/varnish
```

To run the container you need to link the containers you want to run behind the load balancer that Varnish will create.
Varnish will detect all the node containers you pass and add them to the load balancer, we do this with the `setup.sh` file. The only requirement is that when you link your containers you use the name `nodeN`.

## Varnish environment variables

Varnish will use the following environment variables. You can override them if you want

- `VARNISH_VCL_CONF` /etc/varnish/default.vcl
- `VARNISH_LISTEN_ADDRESS` 0.0.0.0
- `VARNISH_LISTEN_PORT` 80
- `VARNISH_ADMIN_LISTEN_ADDRESS` 0.0.0.0
- `VARNISH_ADMIN_LISTEN_PORT` 6082
- `VARNISH_MIN_THREADS` 1
- `VARNISH_MAX_THREADS` 1000
- `VARNISH_THREAD_TIMEOUT` 120
- `VARNISH_SECRET_FILE` /etc/varnish/secret
- `VARNISH_STORAGE_PATH` /varnish_storage
- `VARNISH_STORAGE_FILE` $VARNISH_STORAGE_PATH/varnish_storage.bin
- `VARNISH_STORAGE_SIZE` 1G
- `VARNISH_STORAGE` malloc,$VARNISH_STORAGE_SIZE
- `VARNISH_TTL` 120
- `VARNISH_NCSA_LOGFORMAT` "%h %l %u %t %D \"%r\" %s %b %{Varnish:hitmiss}x \"%{User-agent}i\""

## Credit

- This repository is a fork of [dockerimages/docker-varnish](https://github.com/dockerimages/docker-varnish)
- The VCL config is based on Mattias Geniar [Varnish 4 configuration templates](https://github.com/mattiasgeniar/varnish-4.0-configuration-templates)
