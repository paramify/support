import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Paramify Docs",
  description: "Compliance docs made easier",
  head: [
    ["link", { rel: "icon", href: "/favicon.svg" }],
    [
      "script",
      { id: "hotjar" },
      `(function(h,o,t,j,a,r){
        h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
        h._hjSettings={hjid:3740863,hjsv:6};
        a=o.getElementsByTagName('head')[0];
        r=o.createElement('script');r.async=1;
        r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
        a.appendChild(r);
      })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');`,
    ],
    [
      "script",
      {
        async: "",
        src: "https://www.googletagmanager.com/gtag/js?id=G-PY0PJHYWZV",
      },
    ],
    [
      "script",
      {},
      `
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-PY0PJHYWZV');
    `,
    ],
    [
      "script",
      {
        type: "text/javascript",
        id: "hs-script-loader",
        async: "",
        defer: "",
        src: "//js.hs-scripts.com/24251729.js",
      },
    ],
    ["meta", { name: "og:type", content: "website" }],
    ["meta", { name: "og:locale", content: "en" }],
    ["meta", { name: "og:site_name", content: "Paramify Docs" }],
    ["meta", { name: "og:image", content: "/hero-paramify-sm.png" }],
  ],
  ignoreDeadLinks: [
    // ignore all localhost links
    /^https?:\/\/localhost/,
  ],
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    siteTitle: false,
    logo: {
      light: "/logo-light.svg",
      dark: "/logo-dark.svg",
      alt: "Paramify logo",
    },
    // nav: [
    //   { text: "Home", link: "/" },
    //   { text: "Examples", link: "/markdown-examples" },
    // ],
    sidebar: [
      {
        text: "Introduction",
        items: [
          { text: "Getting Started", link: "/getting-started" },
          { text: "Release Notes", link: "/release-notes" },
          // { text: "Markdown Examples", link: "/markdown-examples" },
          // { text: "Runtime API Examples", link: "/api-examples" },
        ],
      },
      {
        text: "Installation",
        items: [
          { text: "Deployment Options", link: "/deployment-options" },
          { text: "Application Architecture", link: "/app-architecture" },
          { text: "The Paramify Installer", link: "/ppi" },
          {
            text: "Installation Examples",
            collapsed: true,
            items: [
              { text: "AWS EKS via PPI", link: "/deploy-eks-aws" },
              { text: "Azure AKS via Helm", link: "/deploy-helm-azure" },
              { text: "Embedded in AWS", link: "/deploy-embedded-aws" },
              { text: "Embedded in Azure", link: "/deploy-embedded-azure" },
            ],
          },
          {
            text: "Login Options",
            collapsed: true,
            items: [
              { text: "Overview", link: "/login-options" },
              { text: "Microsoft SSO", link: "/login-microsoft" },
              { text: "Okta SSO", link: "/login-okta" },
            ],
          },
          { text: "Embedded DB Backup", link: "/embedded-db-backup" },
          { text: "Users and Teams", link: "/users" },
          { text: "UAT", link: "/uat" },
        ],
      },
      {
        text: "User Guides",
        items: [
          { text: "Risk Solutions", link: "/risk-solutions" },
          { text: "Smart Text & Mentions", link: "/smart-text" },
          { text: "Inheritance", link: "/inheritance" },
          { text: "Reviews", link: "/reviews" },
          { text: "Projects", link: "/projects" },
          { text: "Security Objectives", link: "/objectives" },
          { text: "Controls", link: "/controls" },
          { text: "Key Contacts", link: "/contacts" },
          { text: "Project Overview", link: "/diagrams" },
          { text: "Attachments", link: "/attachments" },
          { text: "Document Robot", link: "/document-robot" },
          { text: "OSCAL", link: "/oscal" },
          { text: "Migrate to Rev5", link: "/migrate-fedramp" },
          { text: "FAQ by Document", link: "/documents/faq" },
          { text: "AI at Paramify", link: "/ai" },
        ],
      },
    ],
    lastUpdated: {},
    socialLinks: [
      { icon: "github", link: "https://github.com/paramify/support" },
      { icon: "linkedin", link: "https://www.linkedin.com/company/paramify" },
      { icon: "youtube", link: "https://www.youtube.com/@paramify" },
    ],
    editLink: {
      pattern: "https://github.com/paramify/support/blob/main/docs/:path",
    },
    footer: {
      message: "Made with ❤️ by Team Paramify",
      copyright:
        "© 2024 Paramify, Inc. All Rights Reserved.<br/><a target='_blank' href='https://www.paramify.com/terms-conditions#privacy-policy'>Privacy Policy &#8599;</a>",
    },
    search: {
      provider: "local",
    },
    outline: "deep",
  },
});

/**
 * Install with Kubenertesdocs
 * Install with Helm
 * Instlall as Virtual Appliance
 * Install in Azure AKS (KOTS)
 * Install in AWS EKS (KOTS)
 * Install in Google GKE (KOTS)
 * Install in Azure with Helm
 * Install in AWS with Helm
 * Install in Google with Helm
 * Install emebedded in AWS EC2 KURL
 * Install embedded in Azure Compute (KURL)
 * Install embedded in Google Compute (KURL)
 *
 *
 */
