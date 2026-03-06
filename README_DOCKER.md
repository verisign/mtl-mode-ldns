# MTL Mode LDNS Zone Signing
The MTL LDNS docker image is dependent on the MTL Mode base image which consists of MTL Mode (version >= 1.2.0), OpenSSL (version 3.5.0+), and LibOQS (version 0.14.0+).

That base image can be built using the MTL repository: (https://github.com/verisign/MTL) using branch 1.2.0

## Building
The MTL LDNS container is build using docker and defaults to enabling several PQC signature schemes and also provides MTL Mode implementations for each of those signature schemes. THese schemes are enabled in the docker/Dockerfile file on line 19 as part of the ./configure command. The examples are built to provide utilities that can be used for key generation, zone signing, and zone verification.

``` ./congiure --with-examples --disable-dane --with-ssl=/usr/local --libdir=/usr/local/lib64 --enable-pqc-algo-fl-dsa --enable-pqc-algo-ml-dsa --enable-pqc-algo-slh-da-sha2 --enable-pqc-algo-slh-dsa-shake --enable-pqc-algo-mayo-1 --enable-pqc-algo-mayo2 --enable-pqc-algo-snova --enable-pqc-algo-mtl ```

The conatiner is built using the compose.yaml file for docker compose:
``` docker compose build ```

Alternative it can be built directly with docker using the labels and parameters defined in the compose.yaml file

# Running
The resulting container contains runnable versions of the ldns example applications. THere is no specified entry point as the container is intended to be run in interactive mode with a mounted voume for the zone files.

Assuming a local directory ```zones``` wiht the zone fiels to sign/verify the following command can be used to start the container placing the zone files in ```/var/dns/zones```

```
docker run -it -v ./zones:/var/dns/zones --entrypoint /bin/bash docker.io/library/pqc_ldns:latest
```


