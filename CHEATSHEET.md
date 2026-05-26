
one-liner that filters to only families with non-zero quota:
az ml compute list-usage --location westus3 -o json \
  | jq -r '["FAMILY","USED","LIMIT","FREE"], (.[] | select(.limit > 0) | [.name.localized_value, .current_value, .limit, (.limit - .current_value)]) | @tsv' \
  | column -t -s $'\t'
If you don't have jq installed:
bashsudo apt install jq    # Debian/Ubuntu
brew install jq   # macOS