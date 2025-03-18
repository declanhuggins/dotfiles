# Load Homebrew environment variables (only once per login)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Set PATH for Python 3.13 (ensure Python is prioritized)
export PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:${PATH}"