# In your python env, run `make install` to install required packages
# and then either `make` for a single test run
# or `make watch` for a continuous pipeline that reruns on changes.
#
# Comments to cyber.security@digital.cabinet-office.gov.uk
# This is free and unencumbered software released into the public domain.

.SILENT: test install-dev install-run watch checks

test: checks
	pytest -sqx --disable-warnings
	echo "✓ Tests passed!"

checks:
	echo "⏳ running pipeline..."
	set -e
	isort --atomic -yq
	black -q .
	flake8 .
	mypy --pretty .
	echo "✓ Checks pipeline passed!"

install-dev:
	set -e
	echo "⏳ installing..."
	pip install -r requirements-dev.txt
	echo "✓ Pip dependencies installed!"

install-run:
	set -e
	echo "⏳ installing..."
	pip install -r requirements.txt
	echo "✓ Pip dependencies installed!"

watch:
	echo "✓ Watch setup, save a python file to trigger test pipeline"
	watchmedo shell-command --drop --ignore-directories --patterns="*.py" --ignore-patterns="*#*" --recursive --command='clear && make --no-print-directory test' .
