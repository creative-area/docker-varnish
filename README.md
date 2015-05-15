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

	VARNISH_PORT 80
	VARNISH_STORAGE_BACKEND malloc,100M
	VARNISHNCSA_LOGFORMAT %h %l %u %t "%r" %s %b "%{Referer}i" "%{User-agent}i"


## Credit

- This repository is a fork of [dockerimages/docker-varnish](https://github.com/dockerimages/docker-varnish)
- The VCL config is based on Mattias Geniar [Varnish 4 configuration templates](https://github.com/mattiasgeniar/varnish-4.0-configuration-templates)
