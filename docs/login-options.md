# Login Options
> Paramify supports multiple login options.

![paramify-login-options](/assets/paramify_login_options.png)

Paramify is able to support multiple options for login in Paramify Cloud and self-hosted environments, including SSO via Google, Microsoft, and Okta. As an alternative you can also leverage a simple email-based "magic link" method, but the other SSO options would be recommended.

## Google
Leverage your Google account for sign-on to Paramify. Follow setup steps in [Google SSO](login-google).

## Microsoft
As part of Microsoft Entra (aka Azure AD) you can setup an app registration for Paramify to support SSO. See setup examples in [Microsoft SSO](login-microsoft).

## Okta
Okta can be used for single sign-on. More details about that configuration are on the [Okta SSO](login-okta) page.

## Email
The simple Email login method will send an email with a "Sign-in" link to your specified email address. This link is only valid for 60 minutes, so you will have to send a new link after your application session expires (which timeout can be configured in your Workspace Settings by an Admin).

:::tip NOTE
Additional Login SSO support via SAML is planned to be available in Q1 of 2025. If you are interested in helping test this option then please reach out to your Client Success or Sales team.
:::
