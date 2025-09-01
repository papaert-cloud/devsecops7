Infracost configuration and setup

Do not store API keys in the repository. Use environment variables or CI secrets.

Local setup (recommended):

1. Run the setup helper to create a local env file:

   source scripts/infracost_setup.sh

2. This creates `~/.infracost.env`. Add this to your shell profile (~/.bashrc or ~/.zshrc):

   source ~/.infracost.env

3. Confirm the key is set:

   echo $INFRACOST_API_KEY

CI setup (GitHub Actions):

1. Create a repository secret named `INFRACOST_API_KEY`.
2. In your workflow, set the env var before running infracost:

   - name: Set Infracost API key
     run: echo "INFRACOST_API_KEY=${{ secrets.INFRACOST_API_KEY }}" >> $GITHUB_ENV

If you need a custom pricing endpoint, set `INFRACOST_PRICING_API_ENDPOINT` accordingly.
