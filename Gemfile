source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.2.0"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "dotenv-rails"
  gem 'mail_interceptor'
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

group :production do
  gem 'redis-rack-cache'
end

gem "rails", "~> 7.0.4", ">= 7.0.4.2"
gem "pg"
gem "puma", "~> 5.0"

gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false

gem 'uri'
gem "sidekiq", "~> 7.0"
gem 'sidekiq-scheduler'
gem "hotwire-livereload", "~> 1.2"
gem 'json', '~> 2.6', '>= 2.6.3'
gem 'net-http'
gem "devise"
gem "autoprefixer-rails"
gem 'bootstrap'

gem 'kaminari'
gem "simple_form", github: "heartcombo/simple_form"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
gem 'actionmailer', '~> 7.0'
gem "breadcrumbs"
gem "sassc-rails"
gem 'font-awesome-sass', '~> 6.1'
gem "jsbundling-rails"
gem 'slack-ruby-client'