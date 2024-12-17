# Google SSO

> Paramify supports login SSO via Google Workspace.

![users-graphic](/assets/hero-paramify.png)

Within the Google Cloud console you can setup an OAuth Client ID for Paramify to support SSO using Google. See other login methods on the [Login Overview](login-options).

## Create an OAuth Client ID

1. Sign in to the [Google Cloud console](https://console.cloud.google.com) as a user with Admin permissions for your domain
2. In the side navigation under _APIs &amp; Services_ click on _Credentials_ then _App registrations_
3. Click _+ CREATE CREDENTIALS_ near the top, then choose _OAuth client ID_
4. For the "Application type" choose _Web Application_
4. Enter an appropriate name (e.g., Paramify SSO)
5. Under _Authorized JavaScript origins_ click _+ ADD URI_ then enter the URL to access Paramify similar to the following:
   https://paramify.mycompany.com
6. Under _Authorized redirect URIs_ click _+ ADD URI_ then enter the same URL to access Paramify plus `/auth/callback`, such as:
   https://paramify.mycompany.com/auth/callback
7. Then click _CREATE_
8. On the _OAuth Client created_ dialog copy the _Client ID_ and _Client secret_ for use later in configuration

## Configure in Self-Hosted

Once the OAuth Client ID is created you can setup Paramify to use this with a few configuration options.

If you are using the [Paramify Platform Installer](ppi#configuring-paramify) then in the config GUI you can check the _Enable Google SSO_ box then enter the `Google Client ID` and `Google Client Secret` that you collected from the creation above.

With a [Helm-based install](deploy-helm-azure) you can add the configuration options to your `values.yaml` in the _configmaps.paramify.data_ section, similar to the following:

```yaml
configmaps:
  paramify:
    data:
      AUTH_GOOGLE_ENABLED: "true"
      AUTH_GOOGLE_CLIENT_ID: "<client_id>"
      AUTH_GOOGLE_CLIENT_SECRET: "<client_secret>"
```

Be sure to replace the `client_id` and `client_secret` with the respective values from the OAuth client ID creation above.
