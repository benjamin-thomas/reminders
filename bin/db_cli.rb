#!/usr/bin/env ruby

# frozen_string_literal: true

begin
  require 'dotenv'
  require 'dbus' # proably not that useful here
  require 'awesome_print'
  # https://ruby-doc.org/stdlib-2.5.1/libdoc/readline/rdoc/Readline.html
  require 'sequel'
  require 'terminal-table'
  require 'chronic'
  require 'colored'
rescue LoadError
  abort("
    # Note: ruby-pg is buggy/unusable in Ubuntu 18.04
    apt remove ruby-pg
    apt-get install ruby-dev libpq-dev
    gem install --user pg

    apt-get install ruby-dotenv ruby-dbus ruby-awesome-print ruby-sequel ruby-pg ruby-terminal-table ruby-chronic ruby-colored
        ")
end

# while true; do ./bin/db_cli.rb ; sleep 1;done

Dotenv.load('~/.env/reminders')
load './config/database.rb'
require_relative '../models/reminder'

require 'pry' ; binding.pry
