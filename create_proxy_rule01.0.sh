#!/bin/bash
sudo application=${DEMO_URL_APPLICATION,,}
envcode=${DEMO_URL_ENVCODE,,}
internalhostname=${DEMO_URL_INTERNALHOSTNAME,,}
internalport=$DEMO_URL_INTERNALPORT
type="https"
echo "application : "$application
echo "envcode : "$envcode
echo "internalhostname : "$internalhostname
echo "internalport : "$internalport
ProxyPass=$type"://"$internalhostname":"$internalport"/"
ProxyPassReverse=$type"://"$internalhostname":"$internalport"/"
supp_apps=("first_app" "second_app" "third_app") # Used to validate supported rule is being defined
ip="0.0.0.0" # External IP used for Route53 to redirect traffic
type="A"
ttl=300
dt=`date +%F"-"%H"-"%M`
hostedzoneid="XXXXXXXXXXXXXXXXX" # Your AWS Hosted Zone id
dnssuffix=".example.com"    #suffix to add to entry
comment="Programmatically created DNS Entry for "$record" created on "$dt
checkpath="/etc/httpd/conf.d/"
initialrecord=$envcode$application

function validate_app
{
    echo "Checking if application name "$application" is valid"
    if ( IFS=$'\n'; echo "${supp_apps[*]}" ) | grep -qFx "$application"; then
        echo "found application "$application" in approved list, continuing"
    else
        echo "error : "$application" was not found in the list of approved applications"
        echo "Approved applications are : "
        for eachapp in "${supp_apps[@]}"
            do
                echo $eachapp
            done
        echo "error: Please provide an approved application! exiting..."
        exit 1
    fi
	echo "Validating port is a number"
		ncheck='^[0-9]+$'
		if ! [[ $internalport =~ $ncheck ]] ; then
			echo "error : port provided is not a number! exiting..."
			exit 1
		else
			echo "Port is a number, continuing"
		fi
	echo "Checking that an environment has been provided"
		if [ -z "$envcode" ] ; then
			echo "error: No environment code has been provided! exiting..."
			exit 1
		else
			echo "Environment code has been provided, continuing"
		fi
	echo "Checking that an internal hostname has been provided"
		if [ -z "$internalhostname" ] ; then
			echo "error: No internal hostname has been provided! exiting..."
			exit 1
		else
			echo "Internal hostname has been provided, continuing"
		fi
}

function build_record
{
    found=""
    rec_count=0
    existing_rec_array=()
    echo "Records to search Route53 : $initialrecord"
    all_records=(`aws route53 list-resource-record-sets --hosted-zone-id $hostedzoneid --output text --query "ResourceRecordSets[*].Name"`)
    echo "Route53 has ${#all_records[@]} registered A Records for $dnssuffix"
    if [ ${#all_records[@]} -gt 0 ]; then
        for record in "${all_records[@]}"
        do
            if [[ "$record" == *"$initialrecord"* ]]; then
                existing_rec_array+=($record)
                found="yes"
                rec_count=$(($rec_count+1))
            fi
        done
    fi
    if [ "$found" = "" ]; then
        record=$initialrecord"01"
        checkurl=$record$dnssuffix
	echo "DNS A Record will be created for "$record
    else
        available=""
        available_count=1
        while [[ "$available" != "true" && "$available_count" -le 20 ]];
            do
                printf -v pad_available_count "%02d" $available_count
                checkurl=$initialrecord$pad_available_count$dnssuffix
                checkurlprefix=$initialrecord$pad_available_count
                checkurldot=$checkurl"."
                echo "Checking if "$checkurl" is available"
                if ( IFS=$'\n'; echo "${existing_rec_array[*]}" ) | grep -qFx "$checkurldot"; then
                    echo "found existing A record for "$checkurl" , skipping"
                else
                    echo "Did not find any existing A record for "$checkurl
                    echo "We can proceed using "$checkurl" for the new A record"
                    record=$checkurlprefix
                    available="true"
                fi
                available_count=$(($available_count+1))
            done
    fi
}

function check_conf_d
{
    checkfile=$checkpath$checkurlprefix".conf"
    echo "Checking for existing conf file "$checkfile
    if [ -f "$checkfile" ]; then
        echo "There is already a config file for this rule. Please advise team to check for orphaned configuration files. Exiting!"
        exit 1
    else
        echo "No existing conf files for "$checkurlprefix" , continuing"
    fi
}

function build_proxy_rule
{
    echo "creating proxy rule for "$record
    conf_file=$checkpath$record".conf"
    if [ "$application" == "first_app" ] ;then
        cat > ${conf_file} << EOF
<VirtualHost *:443>
ServerName $checkurl
SSLEngine on
SSLProxyEngine on
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
SSLCertificateFile      "conf/example-wildcard.crt"
SSLCertificateKeyFile   "conf/example-wildcard.key"
SSLProtocol      all -SSLv3 -SSLv2 -TLSv1
SSLCipherSuite ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256
RewriteEngine On
ProxyPass / $ProxyPass
ProxyPassReverse / $ProxyPassReverse
</VirtualHost>
EOF
    elif [ "$application" == "second_app" ] ;then
        cat > ${conf_file} << EOF
<VirtualHost *:443>
ServerName $checkurl
SSLEngine on
SSLProxyEngine on
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
SSLCertificateFile      "conf/example-wildcard.crt"
SSLCertificateKeyFile   "conf/example-wildcard.key"
SSLProtocol      all -SSLv3 -SSLv2 -TLSv1
SSLCipherSuite ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256
RewriteEngine On
ProxyPass / $ProxyPass
ProxyPassReverse / $ProxyPassReverse
</VirtualHost>
EOF
    elif
[ "$application" == "third_app" ] ;then
        cat > ${conf_file} << EOF
<VirtualHost *:443>
ServerName      $checkurl
SSLEngine on
SSLProxyEngine on
SSLProxyCheckPeerCN off
SSLProxyCheckPeerName off
SSLCertificateFile      "conf/example-wildcard.crt"
SSLCertificateKeyFile   "conf/example-wildcard.key"
SSLProtocol      all -SSLv3 -SSLv2 -TLSv1
SSLCipherSuite ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256
RewriteEngine On
RewriteCond %{REQUEST_METHOD} ^(TRACE|TRACK)
RewriteRule .* - [F]
RewriteCond %{HTTP_HOST} !^$record\.example\.com [NC]
RewriteRule ^/(.*)https://$record$dnssuffix/\$1 [L,R]
ProxyPreserveHost on
ProxyPass / $ProxyPass
ProxyPassReverse / $ProxyPassReverse
</VirtualHost>
EOF
    else
        echo "No proxy build process defined yet for this application. We should never see this message unless the validation has failed!"
    fi
}

function update_route53
{
    TMPFILE=$(mktemp testXXX.json)
    echo "Temporary file created : "$TMPFILE
    cat > ${TMPFILE} << EOF
{
    "Comment":"$comment",
    "Changes":[
    {
        "Action":"CREATE",
        "ResourceRecordSet":{
        "Name":"$record$dnssuffix",
        "Type":"$type",
        "TTL":$ttl,
        "ResourceRecords":[{"Value":"$ip"}]
        }
    }
    ]
}
EOF
backfile="/etc/httpd/route53/backup-"$dt".json"
echo "creating backup of existing Route53 records : "$backfile
aws route53 list-resource-record-sets --hosted-zone-id $hostedzoneid > $backfile
aws route53 change-resource-record-sets --hosted-zone-id $hostedzoneid --change-batch file://$TMPFILE
rm -f $TMPFILE
}

function restart_service
{
    echo "Restarting the httpd service"
    sudo httpd -k restart
    echo "******************************************************************"
    echo ""
    echo "External URL created : "$checkurl
    echo ""
    echo "******************************************************************"
}


validate_app
build_record
check_conf_d
update_route53
build_proxy_rule
restart_service