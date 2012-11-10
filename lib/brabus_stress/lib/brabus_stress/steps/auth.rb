require 'uuid'

module BrabusStress
  module Steps
    module Auth
      include ::BrabusStress::Sync
      
      def connect(memo = nil, &block)
        sync(self, block) do |runner|
          runner.open_connection self.config.server
          runner.send_data :path => "users/auth/balance", :payload => {}
          runner.wait_reply "balancing/move"
          runner.remember_server
        end
      end
      
      def remember_server(memo = nil, &block)
        @server = memo['payload']['shard']
        logger.info "!action | #{memo['reply_to']} | #{(Time.now.utc - memo[:completed_in].to_f).strftime "%H:%M:%S:%L"} | \t %3.6f" % memo['completed_in']
        block.call
      end
      
      def remember_user(memo = nil, &block)
        @user[:id] = memo['payload']['user']['attributes']['id']
        logger.info "!action | #{memo['reply_to']} | #{(Time.now.utc - memo[:completed_in].to_f).strftime "%H:%M:%S:%L"} | \t %3.6f" % memo['completed_in']
        block.call
      end
      
      def balance(memo = nil, &block)
        sync(self, block) do |runner|
          runner.open_connection @server
          runner.send_data :path => "users/auth/balance", :payload => {:shard => @server}
          runner.wait_reply "balancing/settled"
          runner.log_server_data
          runner.log_connected
        end        
      end
      
      def disconnect(memo = nil, &block)
        self.close_connection memo, &block
      end
      
      def signup(memo = nil, &block)
        phone = Time.now.to_i.to_s[-6..-1] + rand(1000).to_s
        uniq = UUID.generate.gsub("-", "")
        @user = {:name => "balancing_#{uniq}", :email => "#{BrabusStress::USER_GROUP}_balancing_#{uniq}@gmail.com", :phone_number => "+#{phone}", :car_number => "0137xx7", :password => "123123", :nickname => "Load Tester"}
        
        sync(self, block) do |runner|
          runner.send_data :path => "users/auth/signup", :payload => {:user => @user}
          runner.wait_reply "users/auth/signup/success"
          runner.remember_user
        end
      end
      
      def confirm(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data :path => "users/auth/confirm", :payload => {:user => {:confirmation_user_id => @user[:id], :confirmation_token => 'Preslavutiy'}}
          runner.wait_reply "users/auth/signup/confirmed"
          runner.log_server_data
        end
      end
      
      def login(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data :path => "users/auth/login", :payload => {:username => @user[:email], :password => '123123'}
          runner.wait_reply "users/auth/login/success"
          runner.log_server_data
        end
      end
            
      def logout(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data :path => "users/auth/logout", :payload => {}
          runner.wait_reply "users/auth/logout/success"
          runner.log_server_data
        end
      end            
    end
  end
end