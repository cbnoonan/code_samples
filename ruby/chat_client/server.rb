# 3 users max
# chat app
# under 5 seconds latency
# global chat room


require 'socket'


class Server

  MESSAGE_LIMIT = 5
  def initialize(port, ip)
    @server = TCPServer.open(ip, port)
    @connections  = {}
    @clients = {}
    @connections[:server] = @server
    @connections[:clients] = @clients

    @last_messages = []
  end

  def run
    loop {
      # for each user connected and accepted by server, it will create a new thread object
      # and which pass the connected client as an instance to the block
      Thread.start(@server.accept) do | client |
        nick_name = client.gets.chomp.to_sym
        @connections[:clients].each do |other_name, other_client|
          if nick_name == other_name || client == other_client
            client.puts "This username already exists"
            Thread.kill self
          end
        end
        puts "#{nick_name} #{client}"
        @connections[:clients][nick_name] = client
        client.puts "Connection established, Thank you for joining! Happy chatting"
        @last_messages.each {|m|
          client.puts "#{Time.now}: #{m}"
        }
        listen_user_messages(nick_name, client)

      end
    }
  end

  def listen_user_messages(username, client)
    loop {
      # get client messages
      msg = client.gets.chomp
      # send a broadcast message, a message for all connected users, but not to its self
      @connections[:clients].each do |other_name, other_client|
        unless other_name == username
          other_client.puts "#{username.to_s}: #{msg}"
          @last_messages << msg

          if @last_messages.length > 5
            @last_messages.shift
          end
        end
      end
    }
  end

end

server = Server.new(3000, "localhost") # (ip, port) in each machine "localhost" = 127.0.0.1
server.run