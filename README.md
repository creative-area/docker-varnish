# Varnish 4 with Docker

This image is intended to provide a caching and load balancing layer in front of web containers.

## Start the container

```bash
$ docker run -d -P \
--link container \
--link another_container \
creativearea/varnish
```

To run the container you need to link the containers you want to run behind the load balancer that Varnish will create.
Varnish will detect all the backend containers you pass and will add them to the load balancer. The only requirement is that your linked backends expose the port 80.

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
- `VARNISH_STORAGE` malloc,100M
- `VARNISH_TTL` 120
- `VARNISH_NCSA_LOGFORMAT` "%h %l %u %t %D \"%r\" %s %b %{Varnish:hitmiss}x \"%{User-agent}i\""

## Credit

- The VCL config is based on Mattias Geniar [Varnish 4 configuration templates](https://github.com/mattiasgeniar/varnish-4.0-configuration-templates)
