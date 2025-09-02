# Setting up Homebrew Tap

Follow these steps to create a Homebrew tap for the `please` tool:

## 1. Create a Homebrew Tap Repository

1. Create a new GitHub repository named `homebrew-please`
   - Repository name must follow the pattern `homebrew-<tap-name>`
   - Make it public

## 2. Initialize the Tap Repository

```bash
# Clone your new tap repository
git clone https://github.com/simonas-dev/homebrew-please.git
cd homebrew-please

# Copy the formula from this repository
cp /path/to/please/Formula/ollama-please.rb ./Formula/ollama-please.rb

# Create initial commit
git add Formula/ollama-please.rb
git commit -m "Add ollama-please formula"
git push origin main
```

## 3. Update Formula with Correct SHA256

After creating your first release (v0.1.0):

1. Download the release tarball:
   ```bash
   curl -L https://github.com/simonas-dev/please/archive/v0.1.0.tar.gz -o please-0.1.0.tar.gz
   ```

2. Calculate the SHA256:
   ```bash
   shasum -a 256 please-0.1.0.tar.gz
   ```

3. Update the formula with the calculated SHA256 and push to the tap repository.

## 4. Create Releases

To create a new release:

```bash
# Tag the release in the main repository
git tag v0.1.0
git push origin v0.1.0
```

The GitHub Actions workflow will automatically create the release with necessary assets.

## 5. Installation Commands

Once the tap is set up, users can install with:

```bash
brew tap simonas-dev/please
brew install ollama-please
```

## Testing the Formula

Test locally before publishing:

```bash
# In the tap repository
brew install --build-from-source ./Formula/ollama-please.rb
brew test ollama-please
```