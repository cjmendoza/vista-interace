require 'mysql'
class Database
  # Copyright Vidaguard 2013class Database
  # Author: Claudio Mendoza


  def self.connect(logger)
    begin
      # connect to the MySQL server
      dbh = Mysql.new('localhost', 'root', 'P@77w0rd!', 'careflow')
#      dbh = Mysql.new('localhost', 'root', '', 'careflow')
    rescue Mysql::Error => e
      logger.error "An error occurred connecting to database, Error code: #{e.errno} Error message: #{e.error}"
    end
    logger.info 'Connected to db'
    dbh
  end
end
