# syntax = docker/dockerfile:1


# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.0
FROM ruby:${RUBY_VERSION}-slim AS base



# Rails app lives here
WORKDIR /myapp


# Set production environment
# Set production environment
ENV RAILS_ENV="development" \
  BUNDLE_PATH="/usr/local/bundle"
# BUNDLE_DEPLOYMENT="1" \
# BUNDLE_WITHOUT="development"




# Throw-away build stage to reduce size of final image
FROM base as build


# Install packages needed to build gems
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git libvips pkg-config libffi-dev


# Copy application code first, then install gems
COPY . .

# Install application gems
RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
  bundle exec bootsnap precompile --gemfile


# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/



# Final stage for app image
FROM base


# Install packages needed for deployment
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y curl default-mysql-client libvips && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives


# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /myapp /myapp
RUN chmod +x /myapp/entrypoint.sh


RUN gem install bundler -v 2.5.23
# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
  chown -R rails:rails db log storage tmp /usr/local/bundle
USER rails:rails


# Entrypoint prepares the database.
ENTRYPOINT ["/myapp/entrypoint.sh"]


# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["sh", "-c", "bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
