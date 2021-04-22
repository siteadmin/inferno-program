FROM ruby:2.7.2

WORKDIR /var/www/inferno

### Install dependencies
COPY Gemfile.docker /var/www/inferno/Gemfile
COPY Gemfile.docker.lock /var/www/inferno/Gemfile.lock
RUN gem install bundler
# Throw an error if Gemfile & Gemfile.lock are out of sync
RUN bundle config --global frozen 1
RUN bundle install

### Install Inferno

RUN mkdir data
COPY public /var/www/inferno/public
COPY resources /var/www/inferno/resources
COPY config* /var/www/inferno/
COPY Rakefile /var/www/inferno/
COPY test /var/www/inferno/test
COPY lib /var/www/inferno/lib
COPY db /var/www/inferno/db
COPY bin /var/www/inferno/bin
COPY db/config.docker.yml db/config.yml

### Set up environment

ENV APP_ENV=production
EXPOSE 4567

CMD ["./bin/run.sh"]
