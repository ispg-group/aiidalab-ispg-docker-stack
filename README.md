# aiidalab-ispg-docker-docker
Dockerfile for AiidaLab ATMOSPEC deployment.

The following extra things are added on top of the `aiidalab/full-stack` image:

1. SLURM queuing manager
2. Additional conda packages (xtb-python, OpenMPI)
   which currently must be installed in root conda environment.
3. HTTPS support

Original images taken from https://github.com/aiidalab/aiidalab-docker-stack

## Creating your own SSL certificates for HTTPS

To get a proper certificate from a trusted Certificate Authority (CA),
you can use Let's encrypt, more specifically its `certbot` tool.

For local development, you can use the [mkcert tool](https://mkcert.dev),
which not only creates the certificates, but also creates a root certificate
and automatically installs it in your system store and in browsers.
No more browser warnings! Here's a quick guide for Ubuntu 20.04.
For other OSes see the official [installation guide](https://github.com/FiloSottile/mkcert#installation).

1. Install dependencies and download the latest mkcert binary for Linux-x86 (it is not abailable as .deb package).
```sh
$ sudo apt install libnss3-tools
$ curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
$ chmod +x mkcert-v*-linux-amd64
$ sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
```

2. Create and install the root CA
```sh
$ mkcert -install
```

3. Generate the certificates for localhost, and possibly other domains
```sh
$ mkcert --cert-file certificates/localhost.crt --key-file certificates/localhost.key localhost 127.0.0.1 it096203.users.bris.ac.uk
```

3. The certificate and private key are now ready in the `certificates/` folder
   so you can now build the docker image.

   **WARNING**: This procedure copies the private key inside the Docker image.
   This is of course only safe when you're building the image locally and not sharing it!
```sh
$ docker build . -t aiidalab-ispg
```

4. (OPTIONAL) Distributing your CA public certificate.
If you need other people to trust you as a certificate authority,
you can distribute the **public** CA cert `rootCA.pem` generated by mkcert.
You can find its location by running
```sh
mkcert -CAROOT
```
**WARNING**: Under any circumstances DO NOT share the `rootCA-key.pem`!
This would allow anybody to spoof trafic to you.
