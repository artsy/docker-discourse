#!/bin/bash

bundle exec rake db:migrate
bundle exec rake assets:precompile
bundle exec config/unicorn_launcher -E production -c config/unicorn.conf.rb
