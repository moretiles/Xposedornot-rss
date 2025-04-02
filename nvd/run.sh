#!/bin/bash

set -eu

get_cves () {
    jq ".vulnerabilities[].cve | \
        .title=.id | \
        .link=\"https://www.cve.org/CVERecord?i=\" + .id | \
        .description = .descriptions[0].value | \
        .pubDate = .published | \
        .language = \"en-us\" | \
        del(.descriptions,.metrics,.configurations,.weaknesses,.references) | \
        {item: .}"
}

cat > ./rss.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
    <channel>
        <!-- Channel Information -->
        <title>Personal CVE FEED</title>
        <link>https://nvd.nist.gov</link>
        <description>Unofficial</description>
        <language>en-us</language>
        <!-- Items (Content) -->
EOF

#curl_string='https://services.nvd.nist.gov/rest/json/cves/2.0'

#jq ".vulnerabilities[].cve | \
#.title=.id | \
#.link=\"https://www.cve.org/CVERecord?i=\" + .id | \
#.description = .descriptions[0].value | \
#.language = \"en-us\" | \
#del(.descriptions,.metrics,.configurations,.weaknesses,.references) | \
#{item: .}" better.json | yq '.' -p json -o xml

truncate -s 0 rss.json
#get_cves < wireguard.json >> ./rss.json
#get_cves < kafka.json >> ./rss.json
#get_cves < windows.json >> ./rss.json
while IFS= read -r cpe; do
    echo "${cpe}"
    curl --silent "https://services.nvd.nist.gov/rest/json/cves/2.0?cpeName=${cpe}" | get_cves >> ./rss.json
    sleep 10
done < ./cpes.txt

jq -s 'sort_by(.item.pubDate) | reverse' rss.json | yq '.[]' -p json -o xml >> rss.xml

cat >> ./rss.xml <<EOF
    </channel>
</rss>
EOF
