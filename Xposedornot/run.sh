#!/bin/bash

set -eu

breach_endpoint='https://api.xposedornot.com/v1/breaches'

mytmp="$(mktemp)"
cat > "${mytmp}" <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">

<channel>
    <title>Personal xposedornot.com data breach feed</title>
    <description>See whether a site you use is on xposedornot.com</description>
EOF

# Constructs a string that matches entries containing any of the domains in the sites file.
# No attempt to escape input is provided so don't let anyone edit the file.
select_sites=""
while IFS= read -r; do
    select_sites+="$(printf '.["domain"] == "%s" or ' "$(printf "${REPLY}" | jq -sRr '@uri')")"
done < ./sites.txt
select_sites+="false"

# The query selects sites, formats fields as rss, and sorts in reverse chronological order.
# yq then converts to xml.
curl --silent "${breach_endpoint}" | jq ".exposedBreaches | map(select(${select_sites}) | \
    .title = .breachID + \" \" + .breachedDate | .pubDate = .breachedDate | \
    .link = \"https://xposedornot.com\" | .description = .exposureDescription) | \
    sort_by(.[\"breachedDate\"]) | reverse" | \
    yq 'map("item": .) | .[][][]' -o xml >> "${mytmp}" # output as xml to mytmp

cat >> "${mytmp}" <<EOF
</channel>

</rss>
EOF

mv "${mytmp}" rss.xml
