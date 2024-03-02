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

ARG GIT_USERNAME
ARG GIT_EMAIL_ADDRESS

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib

RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    git
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

RUN git config --global --add safe.directory /workspace
RUN git config --global user.name ${GIT_USERNAME}
RUN git config --global user.email ${GIT_EMAIL_ADDRESS}

################################################################################
# production
################################################################################
FROM php as prod

ENV TZ Asia/Tokyo

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib

COPY ./app /workspace/app
CMD ["echo", "app is running correctly."]
