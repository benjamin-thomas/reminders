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

begin
  require 'sinatra'
rescue LoadError
  abort('gem install --user sinatra')
end

if ENV['SINATRA_ENV'] != 'dev'
  warn('Use: SINATRA_ENV=dev to enable auto-reload'.yellow.bold)
else
  begin
    require 'sinatra/reloader'
  rescue LoadError
    abort('gem install --user sinatra-reloader')
  end

  require 'pry'
end

Dotenv.load('~/.env/reminders')

$offline = ENV['OFFLINE'] == '1'
if !$offline
  load './config/database.rb'
  require_relative '../models/reminder'
end

Tilt.register Tilt::ERBTemplate, 'html.erb'

def herb(template, options = {}, locals = {})
  render 'html.erb', template, options, locals
end

ONE_MINUTE = 60
ONE_HOUR   = ONE_MINUTE * 60
ONE_DAY    = ONE_HOUR   * 24
ONE_WEEK   = ONE_DAY    * 7

def time_ago(time)
  diff = Time.now - time
  case diff.abs
  when 0...ONE_MINUTE
    '< 1m'
  when ONE_MINUTE...ONE_HOUR
    '< 1h'
  when ONE_HOUR...(ONE_HOUR * 2)
    '< 2h'
  when (ONE_HOUR * 2)...(ONE_HOUR * 3)
    '< 3h'
  when (ONE_HOUR * 3)...(ONE_HOUR * 4)
    '< 4h'
  when (ONE_HOUR * 4)...(ONE_HOUR * 8)
    '< 8h'
  when ONE_HOUR...ONE_DAY
    'today'
  when ONE_DAY...ONE_WEEK
    'this week'
  else
    '> 1w'
  end
end

get '/' do
  return herb :index if $offline

  reminder = Reminder.by_priority.overdue.first
  if reminder
    return redirect "/reminders/#{reminder.id}"
  end

  herb :index
end

get '/reminders/:id' do
  reminder = Reminder.first!(id: params[:id])
  overdue_cnt = Reminder.by_priority.overdue.count
  herb :reminder, locals: {
    r: reminder,
    overdue_cnt: overdue_cnt,
  }
end

post '/reschedule/:id' do
  r = Reminder.first!(id: params[:id])
  r.reschedule!(params[:reschedule_on])
  redirect '/'
end

FakeReminder = Class.new do
  COLUMNS = [ :id, :priority, :trigger_on, :descr ]
  attr_reader *COLUMNS

  def initialize(id: nil, priority: nil, trigger_on: nil, descr: nil)
    @id = id || 1
    @priority = priority || 0
    @trigger_on = trigger_on || Time.now - 1
    @descr = descr || 'Do something'
  end
end

FakeRemindersOverdue = 10.times.map { FakeReminder.new }

get '/overdues' do
  dataset = if $offline
              FakeRemindersOverdue
            else
              Reminder.by_priority.overdue
            end
  herb :overdues, locals: {
    overdues: dataset,
    title: 'Overdue reminders',
  }
end

get '/today' do
  dataset = Reminder.by_priority.today
  herb :overdues, locals: {
    overdues: dataset,
    title: 'Reminders today',
  }
end

# 404 Error!
not_found do
  # status 404
  # erb :oops
  "Oops, don't know this page!"
end
