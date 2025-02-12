Xero-CFML
=========

CFML wrapper for Xero API - use with CFML application servers.

* [Things to note] (#things-to-note)
* [Select an Application Type] (#select-an-application-type)
* [Getting Started] (#getting-started)
* [To Do] (#to-do)
* [Additional Reading] (#additional-reading)
* [Acknowledgements] (#acknowledgements)
* [License] (#license)

## Things to note
* The library focuses on the authentication for Xero's API and provides a basis to be extended.  You can configure this library to use  different Xero application types (see below). Once you've connected to Xero's API, you can read different types of data. This example code is enough to get you going, but is not a complete solution to all your needs. You will need to adapt them for your own use and situation. 
* Not tested on Lucee, please submit issues if you encounter any.


## Select an application type
Xero's API supports [3 application types] (http://developer.xero.com/documentation/getting-started/api-application-types/).  The three types are public, private and partner.  Each application type is supported by this library.  Please [review  each type] (http://developer.xero.com/documentation/getting-started/api-application-types/) to determine the right one for your integration.

* [Public] (http://developer.xero.com/documentation/auth-and-limits/public-applications/)
* [Private] (http://developer.xero.com/documentation/auth-and-limits/private-applications/)
* [Partner] (http://developer.xero.com/documentation/auth-and-limits/partner-applications/)


## Getting Started
### Create a Xero User Account
You can [create a Xero user account](https://www.xero.com/signup) for free.  Xero does not have a designated "sandbox" for development.  Instead you'll use the demo company for development.  Learn how to get started with [Xero Development Accounts](http://developer.xero.com/documentation/getting-started/development-accounts/).

### Install Xero-CFML Library
Download this library and place it in your webroot. There are two directory maps in the Application.cfc file.

	<cfset this.mappings["/cfc"] = getDirectoryFromPath(getCurrentTemplatePath()) & "cfc/" /> 
    <cfset this.mappings["/common"] = getDirectoryFromPath(getCurrentTemplatePath()) & "common/" /> 


## Configuration of API Keys and Certificates
### Securing your resources directory
All configuration files and certificates are located in the resources directory.  In a production environment, you will move this directory outside the webroot for security reasons.  Once you've done that, make sure you update the *pathToConfigJSON* variable in your Application.cfc.  

<cfset pathToConfigJSON = getDirectoryFromPath(getCurrentTemplatePath()) & "resources/config.json"> 

### Config.json
Inside the resources directory, you'll find 4 files.  *the ONLY file used is config.json*.  The other 3 files show required values based on the type of Xero Application.  For example, if you are building a Xero Public App, you can open *config-public.json* and save it as *config.json*, then follow the steps below to set the values for your App.

* config.json
* config-partner.json
* config-private.json
* config-public.json

### Public Application
#### Configure Xero Application
Create a [Xero Public application](https://app.xero.com/Application). Enter a callback domain i.e. localhost.

Open *config.json* file located in the resources directory.  Copy and paste your consumer key and secret.

	"ConsumerKey" : "__YOUR_CONSUMER_KEY__",
	"ConsumerSecret" : "__YOUR_CONSUMER_KEY_SECRET__",

Customize your callback base URL and callback path to point to the location of example/callback.cfm. 

	"CallbackBaseUrl" : "http://localhost:8500",
	"CallbackPath" : "/Xero-CFML-master/example/callback.cfm"

Point your browser to example/index.cfm and click "Connect to Xero" to begin the authentication flow.  Public application access tokens expire after 30 minutes and require the user to authenticate again.

### Private Application
#### Generate Public/Private Key
A [public/private key pair](http://developer.xero.com/documentation/api-guides/create-publicprivate-key/) is required to sign your RSA-SHA1 oAuth requests.  Upload the public key when you create your Xero application.  Store the private key in the /resources/certs/ directory. 

The basic command line steps to generate a public and private key using OpenSSL are as follows:

	openssl genrsa -out privatekey.pem 1024
	openssl req -new -x509 -key privatekey.pem -out publickey.cer -days 1825
	openssl pkcs12 -export -out public_privatekey.pfx -inkey privatekey.pem -in publickey.cer

For this wrapper, you will need to run one additional command to create a .pk8 formatted private key.

	openssl pkcs8 -topk8 -in privatekey.pem -outform DER -nocrypt -out privatekey.pk8

#### Configure Xero Application
Create a [Xero Private application](https://app.xero.com/Application). Select which Xero organization you are connecting to. Upload the *publickey.cer* created as part of the public/private key pair. 


Open *config-private.json* located in the *resources* directory and save it as *config.json*, Open *config.json* then copy and paste the consumer key.

	"ConsumerKey" : "__YOUR_CONSUMER_KEY__",

Point your browser to example/index.cfm and click "Connect to Xero" to begin accessing API resources. Note: private applications connect to a single Xero organzation and therefore do not require the 3-legged oAuth flow.

### Partner Application
Partner applications are only available to those joining [Xero's Add-on Partner Program](http://developer.xero.com/partner/).

After you've applied to join the Partner Program and validated your integration with Xero Developer Evangelist team, build your integration as a Public Application.  Public and Partner applications share all the same data endpoints. Public and Partner application access tokens both expire after 30 minutes, but Partner applications can refresh access tokens when they expire.

Once your integration is complete, contact Xero Developer Evangelist team to review your integration and upgrade from Public to Partner Application.

#### Generate Public/Private Key
A [public/private key pair](http://developer.xero.com/documentation/api-guides/create-publicprivate-key/) is required to sign your RSA-SHA1 oAuth requests.  Upload the public key when you upgrade to a Partner application.  Store the private key  in the /resources/certs directory.

The basic command line steps to generate a public and private key using OpenSSL are as follows:

	openssl genrsa -out privatekey.pem 1024
	openssl req -new -x509 -key privatekey.pem -out publickey.cer -days 1825
	openssl pkcs12 -export -out public_privatekey.pfx -inkey privatekey.pem -in publickey.cer

For this wrapper, you will need to run one additional command to create a .pk8 formatted private key.

	openssl pkcs8 -topk8 -in privatekey.pem -outform DER -nocrypt -out privatekey.pk8

#### Configure Xero Application
Go to your upgraded [Xero Partner application](https://app.xero.com/Application). Enter a callback domain i.e. localhost.

Open *config-partner.json* located in the resources directory and save it as *config.json*, Open *config.json* then copy and paste the consumer key and secret.

	"ConsumerKey" : "__YOUR_CONSUMER_KEY__",
	"ConsumerSecret" : "__YOUR_CONSUMER_KEY_SECRET__",

Customize your callback base URL and callback path to point to the location of example/callback.cfm. 

	"CallbackBaseUrl" : "http://localhost:8500",
	"CallbackPath" : "/Xero-CFML-master/example/callback.cfm"


Point your browser to example/index.cfm and click "Connect to Xero" to begin the authentication flow. 

## To Do
* Refresh Token method for partner applications

## Additional Reading
* [oAuth Bibile](http://oauthbible.com/)

##Acknowledgements
Thanks to the following Developers and Open Source libraries for making the wrapper and samples easier

* [ColdFusion oAuth Library](http://oauth.riaforge.org/) - OAuth 1.0
* [Sharad Gupta](http://www.jensbits.com/2010/05/16/generating-signatures-in-coldfusion-with-rsa-sha1-for-secure-authsub-in-google-analytics/) - RSA-SHA1 signature
* [Matthew Bryant](http://au.linkedin.com/in/mjbryant) - For his work on a Xero API wrapper for Private applications


##License

This software is published under the [MIT License](http://en.wikipedia.org/wiki/MIT_License).

	Copyright (c) 2014 Xero Limited

	Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use,
	copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following
	conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.