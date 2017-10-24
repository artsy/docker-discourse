# docker-discourse

This Docker container is an effort to provide a more self-contained, immediately-deployable
image for the [Discourse](http://www.discourse.org/) discussion platform.

For background, see [this discussion](https://meta.discourse.org/t/can-discourse-ship-frequent-docker-images-that-do-not-need-to-be-bootstrapped/33205/49?u=bradj)
on the Discourse Meta forum.

This image is still very much a work in progress and you are encouraged to
build your own image instead of depending on the Docker Hub automated build,
until the architecture is more settled. I would hope this repository can be
deprecated in the future in favor of a recognized image from the maintainers.

## Usage

### Build and Development

Build the image with `docker build -t artsy/discourse:latest .`

A `docker-compose.yml` file is included for local development and testing.  To build and run the stack locally, run `docker-compose up --build` and discourse will be available at `http://localhost:8080`.

Database migration and regular asset creation are run at application boot time by `/.bootstrap.sh`.

### Environment

You should set the following (hopefully self-explanatory) environment variables for the app container:

* `DISCOURSE_DEVELOPER_EMAILS`
* `DISCOURSE_SMTP_ADDRESS`
* `DISCOURSE_SMTP_PORT`
* `DISCOURSE_SMTP_USER_NAME`
* `DISCOURSE_SMTP_PASSWORD`
* `DISCOURSE_DB_PASSWORD` (the username is pre-set to `postgres`)

These env vars are set explicity in `docker-compose.yml`.  `kubernetes.yml` uses the `envFrom` statement to inject the environment from a `configMap` object named `discourse-environment`.

Copy `discourse-environment.yml.example` to `discourse-environment.yml`, edit this file with your specific settings, and run `kubectl create --save-config -f discourse-environment.yml`.  Note that this needs to be created before creating the Kubernetes deployment.  

### Deployment to Kubernetes

A `kubernetes.yml` file is included for deployment to Kubernetes.  It assumes you are running on AWS and exposes discourse over an ELB with SSL enabled.  The file `nginx.conf` redirects HTTP -> HTTPS if running on a domain that is not `localhost.  Change `MYSERVERCERTIFICATE` to your hosted server certificate. 

`kubernetes.yml` also creates a PersistentVolumeClaim and mounts `/shared` in the `discourse` container for data permanence.

Launch the deployment in your Kubernetes cluster with `kubectl create --save-config -f kubernetes.yml`.

## Known issues and OFI's

- [ ] Log rotation?

## License and Copyright

&copy; 2016 Brad Jones LLC and Civilized Discourse Construction Kit, Inc. and Artsy, Inc.

GPL License.
