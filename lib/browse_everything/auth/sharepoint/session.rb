require 'oauth2'

# BrowseEverything OAuth2 session for 
# Sharepoint provider
module BrowseEverything
  module Auth
    module Sharepoint
      class Session

        OAUTH2_URLS = { 
          :site => 'https://login.microsoftonline.com', 
        }
#          :scope => "https://graph.microsoft.com/.default" 

        def initialize(opts={})

          @config = BrowseEverything.config['sharepoint']

          if opts[:client_id]
            @oauth2_client = OAuth2::Client.new(opts[:client_id], opts[:client_secret],{:authorize_url => authorize_url, :token_url => token_url, :scope => scope}.merge!(OAUTH2_URLS.dup))
            @access_token = OAuth2::AccessToken.new(@oauth2_client, opts[:access_token]) if opts[:access_token]
            @access_token = get_access_token if opts[:access_token].blank?
            @refresh_token = opts[:refresh_token] if @config[:grant_type] == 'authorization_code'
#        @as_user = opts[:as_user]
          end
        end
        
        def authorize_url
          @config['tenant_id']+"/api/oauth2/authorize"
        end

        def token_url
          @config['tenant_id']+"/oauth2/v2.0/token"
        end

        def scope
          @config['scope']
        end

#        def authorize_url(redirect_uri, state=nil)
#          opts = { :redirect_uri => redirect_uri }
#          opts[:state] = state if state
#
#          @oauth2_client.auth_code.authorize_url(opts)
#        end

        def get_access_token(code=nil)

          if @config[:grant_type] == 'client_credentials'
             @access_token ||= @oauth2_client.client_credentials.get_token({:scope => @config[:scope]})
          else
            # assume authorization_code grant_type..?
            @access_token ||= @oauth2_client.auth_code.get_token(code)
          end
        end

        def refresh_token(refresh_token)
          refresh_access_token_obj = OAuth2::AccessToken.new(@oauth2_client, @access_token.token, {'refresh_token' => refresh_token})
          @access_token = refresh_access_token_obj.refresh!
        end

        def build_auth_header
          "BoxAuth api_key=#{@api_key}&auth_token=#{@auth_token}"
        end

        def get(url, raw=false)
          uri = URI.parse(url)
          request = Net::HTTP::Get.new( uri.request_uri )
          resp = request( uri, request, raw )
        end

        def delete(url, raw=false)
          uri = URI.parse(url)
          request = Net::HTTP::Delete.new( uri.request_uri )
          resp = request( uri, request, raw )
        end

        def request(uri, request, raw=false, retries=0)

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          #http.set_debug_output($stdout)

          if @access_token
            request.add_field('Authorization', "Bearer #{@access_token.token}")
          else
            request.add_field('Authorization', build_auth_header)
          end


          request.add_field('As-User', "#{@as_user}") if @as_user

          response = http.request(request)

          if response.is_a? Net::HTTPNotFound
            raise RubyBox::ObjectNotFound
          end

          # Got unauthorized (401) status, try to refresh the token
          if response.code.to_i == 401 and @refresh_token and retries == 0
            refresh_token(@refresh_token)
            return request(uri, request, raw, retries + 1)
          end

          sleep(@backoff) # try not to excessively hammer API.

          handle_errors( response, raw )
        end

        def do_stream(url, opts)
          params = {
            :content_length_proc => opts[:content_length_proc],
            :progress_proc => opts[:progress_proc]
          }

          if @access_token
            params['Authorization'] = "Bearer #{@access_token.token}"
          else
            params['Authorization'] = build_auth_header
          end

          params['As-User'] = @as_user if @as_user

          open(url, params)
        end

        def handle_errors( response, raw )
          status = response.code.to_i
          body = response.body
          begin
            parsed_body = JSON.parse(body)
          rescue
            msg = body.nil? || body.empty? ? "no data returned" : body
            parsed_body = { "message" =>  msg }
          end

          # status is used to determine whether
          # we need to refresh the access token.
          parsed_body["status"] = status

          case status / 100
          when 3
            # 302 Found. We should return the url
            parsed_body["location"] = response["Location"] if status == 302
          when 4
            raise(RubyBox::ItemNameInUse.new(parsed_body, status, body), parsed_body["message"]) if parsed_body["code"] == "item_name_in_use"
            raise(RubyBox::AuthError.new(parsed_body, status, body), parsed_body["message"]) if parsed_body["code"] == "unauthorized" || status == 401
            raise(RubyBox::RequestError.new(parsed_body, status, body), parsed_body["message"])
          when 5
            raise(RubyBox::ServerError.new(parsed_body, status, body), parsed_body["message"])
          end
          raw ? body : parsed_body
        end
      end
    end
  end
end
