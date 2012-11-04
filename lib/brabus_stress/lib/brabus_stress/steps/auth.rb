module BrabusStress
  module Steps
    module Auth      
      def balance
        self.connect!
        
        send_data :path => "users/auth/balance", :payload => {}
        data = wait_reply "balancing/move"
        
        send_data :path => "users/auth/balance", :payload => {:shard => data['payload']['shard']}
        data = wait_reply "balancing/settled"
      end
      
      def signup_and_login
        uniq = Time.now.to_i.to_s[0..6] + rand(1000).to_s
        
        user = {:name => "balancing_#{uniq}", :email => "balancing_#{uniq}@gmail.com", :phone_number => "+#{uniq}", :car_number => "0137xx7", :password => "123123", :nickname => "Load Tester"}
        
        send_data :path => "users/auth/signup", :payload => {:user => user}
        data = wait_reply "users/auth/signup/success"
        
        send_data :path => "users/auth/confirm", :payload => {:user => {:confirmation_user_id => data['payload']['user']['attributes']['id'], :confirmation_token => 'Preslavutiy'}}
        wait_reply "users/auth/signup/confirmed"
        
        send_data :path => "users/auth/login", :payload => {:username => data['payload']['user']['attributes']['email'], :password => '123123'}
        wait_reply "users/auth/login/success"
      end
            
    end
  end
end