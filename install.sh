#!/bin/bash
set -e
echo "Installing claudesaver..."
claude plugin marketplace add djfrez/claudesaver
claude plugin install claudesaver@djfrez
echo "Done. Start a new Claude session to activate."
