# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /myapp

ENV RAILS_ENV="production" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"


FROM base AS build

RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y build-essential git libvips pkg-config libffi-dev libpq-dev && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY attendance_app/ .

RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
  bundle exec bootsnap precompile --gemfile

RUN bundle exec bootsnap precompile app/ lib/


FROM base

RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y curl libvips libpq5 && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /myapp /myapp
RUN chmod +x /myapp/entrypoint.sh

RUN useradd rails --create-home --shell /bin/bash && \
  chown -R rails:rails db log storage tmp public /usr/local/bundle
USER rails:rails

ENTRYPOINT ["/myapp/entrypoint.sh"]

EXPOSE 3000
CMD ["sh", "-c", "bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
