# frozen_string_literal: true

require 'oauth2'

# BrowseEverything OAuth2 session for
# Sharepoint provider
module BrowseEverything
  module Auth
    module Sharepoint
      class Session
        OAUTH2_URLS = {
          site: 'https://login.microsoftonline.com'
        }.freeze

        def initialize(opts = {})
          token_info = opts[:access_token]&.symbolize_keys

          if opts[:client_id]
            @oauth2_client = OAuth2::Client.new(opts[:client_id],
                                                opts[:client_secret],
                                                {
                                                  authorize_url: authorize_url(opts[:tenant_id]),
                                                  token_url: token_url(opts[:tenant_id]),
                                                  redirect_uri: opts[:redirect_uri],
                                                  scope: opts[:scope]
                                                }.merge!(OAUTH2_URLS.dup))
            return if token_info.blank?
            @access_token = OAuth2::AccessToken.new(@oauth2_client,
                                                    token_info[:token],
                                                    {
                                                      refresh_token: token_info[:refresh_token],
                                                      expires_in: token_info[:expires_in]
                                                    })
          end
        end

        def authorize_url(tenant_id)
          tenant_id + "/oauth2/v2.0/authorize"
        end

        def token_url(tenant_id)
          tenant_id + "/oauth2/v2.0/token"
        end

        def get_access_token(code)
          @access_token = @oauth2_client.auth_code.get_token(code)
        end

        def refresh_token
          @access_token = @access_token.refresh!
        end
      end
    end
  end
end
