# Published privacy policy — maintenance and recovery

GitHub Pages is enabled from **main /docs**, with HTTPS enforcement. Both pages were verified publicly without authentication on 2026-10-29:

- Support: https://miguelxhubgitty.github.io/dont-touch-me/
- Privacy: https://miguelxhubgitty.github.io/dont-touch-me/privacy.html

The live policy HTML matched `docs/privacy.html` after newline normalization. There is no remaining hosting activation step for the owner. Use these URLs in the stores; supply a real monitored email where a store requires one.

## Updating the policy

1. Review changed data practices as the operator and update `release/PRIVACY_POLICY.md` and `docs/privacy.html` together. Keep support details current.
2. Commit/push to main; GitHub Pages deploys the docs folder automatically.
3. Verify the public HTTPS page still loads and matches the approved text. Update the store disclosures whenever the app's actual practices change.

The source pages contain no JavaScript, forms, analytics or external fonts. GitHub hosting and separately initiated issue-tracker support are subject to GitHub's website policies; they are separate from the offline game. The repository is public; no visibility or access permissions were broadened to publish these pages.

## Recovery only if hosting is disabled later

In the repository's **Settings > Pages**, choose **Deploy from a branch**, branch **main**, folder **/docs**, save and wait for the deployment. Read the actual URL shown by GitHub, then verify the support and privacy pages anonymously before using them in store forms. Do not create a custom domain or paid service merely to restore this existing project site.

If the source repository becomes private on a free plan, decide on a separate public policy-only repository or another suitable free host; do not expose private source just to enable hosting.

Official instructions: [GitHub Pages setup](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site), [publishing source](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
