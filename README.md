# URL Automation Script

## Purpose
Shell script developed to automate the creation of external URLs on an apache
reverse proxy server.

## Inputs
The script requires a number of variables defined on the pipeline to create the external URL rule

Variable Name        | Value
---------------------|----------------------
DEMO_URL_ENVCODE | a double digit code which represents a deployment environment
DEMO_URL_APPLICATION | **Must be either** first_app or second_app or third_app
DEMO_URL_INTERNALHOSTNAME | Either the shortname or FQDN of the instance. Do **NOT** prefix with http or https and do not add a port
DEMO_URL_INTERNALPORT | portnumber only. **NO letters or slash**

## Method
The script performs the following actions based on the variables provided

## Functions
- validate_app function
  - This function performs a number of checks to ensure the input variables are valid and converts all to lowecase
- build_record function
  - This function is used to work out the next available external host for the environment and application provided.
  - This is performed by checking against AWS Route53 for existing records. If they exists the code will increment the suffix number until it finds one which does not exist
  - For example if the env is Z1 and the app is first_app the process will check for z1first_app01, if it exists it will try z1first_app02 and continue until an unused value is calculated
- check_conf_d
  - This function checks to ensure there are no existing apache configuration files for this rule
- update_route53
  - A json file is generated which is used by the AWS CLI to create the Route53 A Record for the external URL.
Prior to creating the rule the existing Route53 A Records are backed up to a json file.
- build_proxy_rule
  - Used to build the re-write rule for this external url. Will be stored as a drop-in file on the Apache server
- restart_service
  - Restarts the httpd process

### Known issues
None

### Planned enhancements
None presently

## Author
**Dave Hart**
[link to blog!](https://davehart.co.uk)

