#!/bin/bash

# This is a prometheus node-exporter specific script to check certificates
# and export them to a file, for the file exporter to pick up.

input_file=$1
out_file=/var/lib/prometheus/node-exporter/tls_certificate_validity.prom
tmp_file=${out_file}.tmp

readarray -t urls < ${input_file}

get_expiry_timestamp () {
  expiry_date=$(echo | openssl s_client -servername $1 -connect ${1}:443 2>/dev/null | openssl x509 -noout -enddate | sed 's/.*=//')

  date -d "${expiry_date}" +%s
}


echo "# HELP tls_certificate_validity Remaining time in seconds the certificate is valid for" > $tmp_file
echo "# TYPE tls_certificate_validity gauge" >> $tmp_file

for url in ${urls[@]}; do
  now=$(date +%s)
  time_remaining=$(( $( get_expiry_timestamp $url ) - $now ))

  echo "tls_certificate_validity{domain=\"${url}\"} ${time_remaining}" >> $tmp_file
done
mv $tmp_file $out_file

