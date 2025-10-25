FROM ruby:3.3.8

RUN apt-get update -qq && \
    apt-get install -y build-essential libsqlite3-dev sqlite3 libssl-dev libffi-dev

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .

RUN chmod +x docker-entrypoint.sh

VOLUME /app/db

EXPOSE 9292

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:9292", "config.ru"]
