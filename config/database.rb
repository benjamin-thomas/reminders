DB_DIR = File.expand_path('~/.local/var/my_reminders')
DB_EXPORT_PATH = File.join(DB_DIR, 'reminders.csv')

# https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html
DB = Sequel.connect(ENV.fetch('DATABASE_URL'), connect_timeout: 10)
db_size_res = DB.fetch('SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;').first
db_size_res[:max_size] = '20 MB'
ap(db_size_res)
DB.logger = DB_LOGGER = Logger.new(STDOUT)

# See if connection is stable after long sleep/wake cycle
DB.extension(:connection_validator)
DB.pool.connection_validation_timeout = 5 # default is 3600s (every hour), -1 to validate every connections

# DB.extension(:connection_expiration)
# DB.pool.connection_expiration_timeout = 60*5 # Default is 3600 # 1 hour
