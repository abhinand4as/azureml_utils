# Azure ML CLI Cheatsheet

## Quota

List compute quota for a region, showing only families with a non-zero limit:

```bash
az ml compute list-usage --location westus3 -o json \
  | jq -r '["FAMILY","USED","LIMIT","FREE"],
           (.[] | select(.limit > 0)
               | [.name.localized_value, .current_value, .limit, (.limit - .current_value)])
           | @tsv' \
  | column -t -s $'\t'
```
