class Credentials < Google::Auth::UserRefreshCredentials

  def fetch_access_token(options={})
    return build_token_hash if self.access_token
    super(options)
  end

  private

    def build_token_hash
      { 'access_token' => self.access_token }
    end
end
