== Sharepoint Provider ==

This provider will allow browse-everything to access a specific SharePoint location

First register an application on azure to give access to the relevant location

https://learn.microsoft.com/en-us/graph/auth-v2-service?tabs=http

To us the sharepoint provider add the following to config/browse_everything_providers.yml

sharepoint:
  client_id: MyAppClientID
  client_secret: MyAppClientSecret
  tenant_id: MyAzuerTenantID
  grant_type: client_credentials
  scope: https://graph.microsoft.com/.default
  domain: mydomain.sharepoint.com
  site_name: MySiteName
