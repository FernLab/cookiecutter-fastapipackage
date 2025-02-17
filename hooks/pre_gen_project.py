import re
import sys
from datetime import datetime

# Regex for validating Python module names
MODULE_REGEX = r'^[_a-zA-Z][_a-zA-Z0-9]+$'

# The project slug to validate
module_name = '{{ cookiecutter.project_slug}}'
module_short_description = '{{cookiecutter.project_short_description}}'

# Check if the module name is valid
if not re.match(MODULE_REGEX, module_name):
    print('ERROR: The project slug (%s) is not a valid Python module name. '
          'Please do not use a - and use _ instead' % module_name)

    #Exit to cancel project
    sys.exit(1)

if len(module_short_description) > 120:
    print(f'ERROR: The project description must have up to 100 characters. This has ({len(module_short_description)}) length!')

    # Exit to cancel project
    sys.exit(1)
