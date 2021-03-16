module SendGridWebApi::Helper
  extend self  
  
  def run_sendgrid_query(apikey)
    @client = SendGridWebApi::Client.new(apikey)
    result = yield
    raise "it returns the following errors: #{result}" unless result.eql?({"message"=>"success"})
  end

  ###this accepts subuser array
  def create_sub_user_account(apikey, users)
    users.each do |user, data|
      #load users
      run_sendgrid_query(apikey) do
        @client.sub_user.management.add(data[:account].merge!(:username => user))
      end
            
      #active user for send email
      run_sendgrid_query(apikey){@client.sub_user.management.enable(:user => user)}
    
      #assign ip
      unless data[:assigned_ips].empty?
        run_sendgrid_query(apikey){@client.sub_user.ip_management.assign_ip :user => user, :ip => data[:assigned_ips]}
      end
      #load apps
      unless data[:applications].empty?
        data[:applications].each do |app_name, options|
          run_sendgrid_query(apikey){@client.sub_user.apps.activate(:user => user, :name => app_name)}
          unless options.empty?
            run_sendgrid_query(apikey){@client.sub_user.apps.customize(options.merge!(:user => user, :name => app_name))}
          end
        end
      end
    end
  end
end