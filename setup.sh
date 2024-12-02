#!/bin/bash

# Define project name
PROJECT_NAME="pyeloquent"

# Create project directories
echo "Creating project structure..."
mkdir -p $PROJECT_NAME/{${PROJECT_NAME},tests,docs,.github/workflows}

# Create __init__.py for package and test directories
echo "Creating __init__.py files..."
touch $PROJECT_NAME/${PROJECT_NAME}/__init__.py
touch $PROJECT_NAME/tests/__init__.py

# Create core.py and utils.py
echo "Creating source files..."
cat > $PROJECT_NAME/${PROJECT_NAME}/core.py <<EOL
# Core functionality for pyeloquenl

def example_function():
    return "This is an example function."
EOL

cat > $PROJECT_NAME/${PROJECT_NAME}/utils.py <<EOL
# Utility functions for pyeloquenl

def helper_function():
    return "This is a helper function."
EOL

# Create test_core.py
echo "Creating test files..."
cat > $PROJECT_NAME/tests/test_core.py <<EOL
import unittest
from ${PROJECT_NAME}.core import example_function

class TestCore(unittest.TestCase):
    def test_example_function(self):
        self.assertEqual(example_function(), "This is an example function.")

if __name__ == "__main__":
    unittest.main()
EOL

# Create README.md
echo "Creating README.md..."
cat > $PROJECT_NAME/README.md <<EOL
# ${PROJECT_NAME.capitalize()}

A Python library for machine learning with an emphasis on eloquence.

## Features
- Core utilities for ML workflows
- Helper functions for data preprocessing

## Installation
\`\`\`bash
pip install ${PROJECT_NAME}
\`\`\`

## License
This library is licensed under the Business Source License 1.1 (BSL 1.1). Certain usage restrictions apply. The license will convert to an open-source license on the Change Date. See the LICENSE file for details.
EOL

# Create LICENSE
echo "Creating LICENSE..."
cat > $PROJECT_NAME/LICENSE <<EOL
Business Source License 1.1

Terms:
- Change Date: YYYY-MM-DD
- Additional Use Grant: Please specify here.

See the full license text at https://mariadb.com/bsl11/.
EOL

# Create pyproject.toml
echo "Creating pyproject.toml..."
cat > $PROJECT_NAME/pyproject.toml <<EOL
[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "${PROJECT_NAME}"
version = "0.1.0"
description = "A Python library for machine learning workflows."
authors = [{name = "Your Name", email = "youremail@example.com"}]
license = {file = "LICENSE"}
dependencies = []
EOL

# Create .gitignore
echo "Creating .gitignore..."
cat > $PROJECT_NAME/.gitignore <<EOL
# Byte-compiled files
__pycache__/
*.pyc
*.pyo

# Distribution files
dist/
build/
*.egg-info/

# Environment files
.env
EOL

# Create CI/CD workflow file
echo "Creating CI/CD workflow..."
cat > $PROJECT_NAME/.github/workflows/python-package.yml <<EOL
name: Python Package

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: pytest
EOL

echo "Project setup completed! Navigate to the $PROJECT_NAME directory to view your project."


# write a file to c:\repositories\pyeloquent\location.log with the actual working directory that all the above commands were executed in
echo "Writing location.log..."
echo $(pwd)



read -p "Press any key to continue..."
