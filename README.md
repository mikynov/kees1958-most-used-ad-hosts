# Kees1958's Most used Ad hosts

[Kees1958/W3C_annual_most_used_survey_blocklist](https://github.com/Kees1958/W3C_annual_most_used_survey_blocklist) converted to _hosts_ format.

Kees1958 stopped providing a hosts file in [953338a](https://github.com/Kees1958/W3C_annual_most_used_survey_blocklist/commit/953338a54ed8f405862fd7fcc91acb04c627aedd) (the latest commit with _hosts_ file was [6b8c241](https://github.com/Kees1958/W3C_annual_most_used_survey_blocklist/tree/6b8c2411f22dda68b0b41757aeda10e50717a802)), see discussion in [issues/59](https://github.com/Kees1958/W3C_annual_most_used_survey_blocklist/issues/59).

On **every Friday evening** (UTC), GitHub Action checks if Kees1958's [ABP list](https://github.com/Kees1958/W3C_annual_most_used_survey_blocklist/blob/master/EU_US_MV3_most_common_ad%2Btracking_networks.txt) was updated and generate a new _hosts_ file if necessary.

Conversion is simple, just parse domain on each line, prepend with `0.0.0.0` and send to output. Domains are filtered using simple [Whitelist](https://github.com/mikynov/kees1958-most-used-ad-hosts/blob/master/.github/scripts/abp2hosts.sh#L16).
