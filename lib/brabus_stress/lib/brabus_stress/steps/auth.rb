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
          runner.rebalance
          runner.wait_reply "balancing/settled"
          runner.log_connected
        end
      end
      
      def disconnect(memo = nil, &block)
        self.close_connection memo, &block
      end
      
      def rebalance(memo = nil, &block)
        self.open_connection memo['payload']['shard'] do
          self.send_data :path => "users/auth/balance", :payload => {:shard => memo['payload']['shard']}, &block
        end
      end
            
      def signup_and_login(memo = nil, &block)
        phone = Time.now.to_i.to_s[-6..-1] + rand(1000).to_s
        uniq = UUID.generate.gsub("-", "")
        @user = {:name => "balancing_#{uniq}", :email => "#{BrabusStress::USER_GROUP}_balancing_#{uniq}@gmail.com", :phone_number => "+#{phone}", :car_number => "0137xx7", :password => "123123", :nickname => "Load Tester"}
        
        sync(self, block) do |runner|
          runner.send_data :path => "users/auth/signup", :payload => {:user => @user}
          runner.wait_reply "users/auth/signup/success"
          runner.send_confirm
          self.wait_reply "users/auth/signup/confirmed"
          runner.login
          self.wait_reply "users/auth/login/success"
        end
      end
      
      def send_confirm(memo = nil, &block)
        self.send_data :path => "users/auth/confirm", :payload => {:user => {:confirmation_user_id => memo['payload']['user']['attributes']['id'], :confirmation_token => 'Preslavutiy'}}, &block
      end
      
      def login(memo = nil, &block)
        self.send_data :path => "users/auth/login", :payload => {:username => @user[:email], :password => '123123'}, &block
      end
      
      def logout(memo = nil, &block)
        sync(self, block) do |runner|
          runner.send_data :path => "users/auth/logout", :payload => {}
          runner.wait_reply "users/auth/logout/success"
        end
      end            
    end
  end
end