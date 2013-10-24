class Database
  # Copyright Vidaguard 2013class Database
  # Author: Claudio Mendoza


  def self.connect
    begin
      # connect to the MySQL server
      dbh = Mysql.new('localhost', 'root', '', 'careflow')
    rescue Mysql::Error => e
      puts "An error occurred"
      puts "Error code:    #{e.errno}"
      puts "Error message: #{e.error}"
    end
    puts 'Connected to db'
    dbh
  end
end
