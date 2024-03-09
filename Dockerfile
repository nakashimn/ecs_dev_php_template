################################################################################
# builder
################################################################################
FROM php as builder

RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    tzdata

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN mv composer.phar /usr/local/bin/composer

################################################################################
# development
################################################################################
FROM php as dev

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib

RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    git
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

RUN git config --global --add safe.directory /workspace

################################################################################
# testing
################################################################################
FROM php as test

ENV TZ Asia/Tokyo

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib
RUN composer require --dev phpunit/phpunit

COPY ./app/src /app/src
COPY ./app/assets /app/assets
COPY ./app/test /app/test
CMD ["vender/phpunit/phpunit/phpunit", "tests"]

################################################################################
# production
################################################################################
FROM php as prod

ENV TZ Asia/Tokyo

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib

COPY ./app/src /app/src
COPY ./app/assets /app/assets
CMD ["echo", "app is running correctly."]
