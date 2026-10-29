# Publish the privacy policy with free GitHub Pages

Ready-to-host files: `docs/index.html` (support page), `docs/privacy.html` (policy), and `docs/.nojekyll`. No trackers, JavaScript, forms, or external fonts are added. The policy source is `release/PRIVACY_POLICY.md`.

The repository was verified **public** with its issue tracker enabled on 2026-10-29, so it qualifies for GitHub Pages with GitHub Free. No hosting setting was changed during this task, and no URL is claimed live.

1. Review and approve `PRIVACY_POLICY.md` as the app operator. Confirm the final binary matches it and the public GitHub issue tracker is a support channel you will monitor. Supply the stores' required working support/review email separately; no email address has been invented.
2. In the repository, open **Settings > Pages**.
3. Under **Build and deployment**, select **Deploy from a branch**. Choose branch **main**, folder **/docs**, and save.
4. Wait for deployment, then open the HTTPS address shown by GitHub. The expected project-site URLs are `https://miguelxhubgitty.github.io/dont-touch-me/` and `https://miguelxhubgitty.github.io/dont-touch-me/privacy.html`; use only the URL that actually loads successfully after deployment.
5. Verify the policy and support link in a signed-out/private browser on both phone and desktop. Check accessibility and that no login is required to read the policy. The issue tracker requires GitHub sign-in to submit an issue; the game does not.
6. Paste the tested privacy URL into Google Play's privacy-policy field and Apple's Privacy Policy URL field. Use the verified support page for the support website, and enter a real monitored email where required.
7. Keep Markdown and HTML policy content synchronized when app practices change. If hosting moves, update every store URL.

GitHub hosts these pages under its own website privacy practices; serving a support/policy website is separate from the offline game's behavior. Do not add analytics or contact forms without updating the website disclosures appropriately. GitHub Pages should host this informational material, not be used as a backend or payment service.

If the source repository later becomes private on a free plan, use a separate **public policy-only repository** or another suitable host. Do not make private source public merely to turn on Pages without deciding that explicitly.

Official instructions: [creating a GitHub Pages site](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site), [publishing source configuration](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
