# Sharepoint Provider

This provider will allow browse-everything to access Sharepoint on behalf of a specific user. It routes through the `/me/joinedTeams` and `/me/drives` Graph API endpoints. This will list Teams that the user belongs to and the user's personal drives. Within each Team it will expand to list any child drives or files that the user has permission to access.

https://learn.microsoft.com/en-us/graph/auth-v2-user?tabs=http

Prerequisite:
  * App must be registered in the Entra Admin center to receive client_id, client_secret, and tenant_id.
  * If using .default endpoint as your scope, you must register API permissions for your application. Minimum permissions:
    * Files.Read
    * Files.Read.All
    * Files.Read.Selected
    * offline_access
    * openid
    * profile
    * Team.ReadBasic.All
    * User.Read

To use the sharepoint provider add the following to `config/browse_everything_providers.yml`:

```
sharepoint:
  client_id: MyAppClientID
  client_secret: MyAppClientSecret
  tenant_id: MyAzureTenantID
  redirect_uri: https://example.com/browse/connect
  scope: offline_access https://graph.microsoft.com/.default
```
