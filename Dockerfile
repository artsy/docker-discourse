FROM ruby:2.3

ENV DISCOURSE_VERSION 1.8.9
ENV HOMEDIR /var/www/discourse

# This will do an apt-get update
RUN curl --silent --location https://deb.nodesource.com/setup_4.x | bash -

# Install dependencies
RUN apt-get install -yqq --no-install-recommends \
    libxml2 \
    wget \
    runit \
    lsof \
    vim \
    nodejs mysql-client postgresql-client sqlite3 \
    && npm install uglify-js@2.8.27 -g \
    && npm install svgo -g \
    && apt-get install -yqq --no-install-recommends \
    advancecomp jhead jpegoptim libjpeg-turbo-progs optipng libjemalloc-dev

COPY install-imagemagick /tmp/install-imagemagick
RUN /tmp/install-imagemagick

COPY install-pngcrush /tmp/install-pngcrush
RUN /tmp/install-pngcrush

COPY install-gifsicle /tmp/install-gifsicle
RUN /tmp/install-gifsicle

COPY install-pngquant /tmp/install-pngquant
RUN /tmp/install-pngquant

COPY install-nginx /tmp/install-nginx
RUN /tmp/install-nginx

RUN rm -rf /var/lib/apt/lists/*

# Get discourse
RUN mkdir -p /var/www && cd /var/www &&\
    git clone https://github.com/discourse/discourse.git &&\
    cd discourse &&\
    git remote set-branches --add origin tests-passed &&\
    git checkout v$DISCOURSE_VERSION

# Update bundler and rake
RUN gem install bundler
RUN gem install rake -v '11.3.0'

# Bundle install
RUN cd $HOMEDIR &&\
    bundle install --deployment \
    --without test --without development

# Clean up
RUN find $HOMEDIR/vendor/bundle -name tmp -type d -exec rm -rf {} +

# Create shared resources
RUN cd $HOMEDIR \
    && mkdir -p tmp/pids \
	&& mkdir -p tmp/sockets \
	&& touch tmp/.gitkeep \
	&& mkdir -p                    /shared/log/rails \
	&& bash -c "touch -a           /shared/log/rails/{production,production_errors,unicorn.stdout,unicorn.stderr}.log" \
	&& bash -c "ln    -s           /shared/log/rails/{production,production_errors,unicorn.stdout,unicorn.stderr}.log $HOMEDIR/log" \
	&& bash -c "mkdir -p           /shared/{uploads,backups}" \
	&& bash -c "ln    -s           /shared/{uploads,backups} $HOMEDIR/public"

# Set up nginx
COPY nginx.conf /etc/nginx/conf.d/discourse.conf

RUN sed -i "s/pid \/run\/nginx.pid\;/daemon off\;/" /etc/nginx/nginx.conf

RUN rm /etc/nginx/sites-enabled/default \
    && mkdir -p /var/nginx/cache

# Set up services
COPY service /etc/service

# Configure ImageMagick policy
COPY policy.xml /usr/local/etc/ImageMagick-6/policy.xml

# Set runtime env
ENV RAILS_ENV production
ENV RUBY_GC_MALLOC_LIMIT 90000000
ENV DISCOURSE_DB_HOST postgres
ENV DISCOURSE_REDIS_HOST redis
ENV UNICORN_PORT 3000
ENV UNICORN_WORKERS 3
ENV UNICORN_SIDEKIQS 1

COPY bootstrap.sh $HOMEDIR/bootstrap.sh

EXPOSE 80
CMD ["/usr/bin/runsvdir", "-P", "/etc/service"]
