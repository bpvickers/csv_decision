FROM ruby:3.3.0
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile csv_decision.gemspec ./
RUN gem update bundler
# RUN bundle install
