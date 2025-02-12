<!---
Description:
============
	Xero oAuth Connector

License:
============
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

History:
============
10/15/14 - Sid Maestre - created
--->

<cfcomponent displayname="xero">

	<cffunction name="init" returntype="xero" output="true">
		<cfreturn this>
	</cffunction>

	<cffunction name="getHttpURL" access="public" returntype="string">
		<cfreturn variables.sHttpURL>
	</cffunction>
	<cffunction name="setHttpURL" access="public" returntype="void">
		<cfargument name="sHttpURL" type="string" required="yes">
		<cfset variables.sHttpURL = arguments.sHttpURL>
	</cffunction>

	<!--- attempt to build up a requestToken URL from the config details --->
	<cffunction name="requestToken" access="public" returntype="struct">
		
			<cfset var config = application.config>
			<cfset var oResultRequest = StructNew()>

			<cfset var oToken = CreateObject("component", "cfc.oauth.oauthtoken").createEmptyToken()>

			<!--- set up the required objects including signature method--->
			<cfif config.AppType EQ "PUBLIC">
				<cfset var oReqSigMethodSHA = CreateObject("component", "cfc.oauth.oauthsignaturemethod_hmac_sha1")>
				<cfset var oConsumer = CreateObject("component", "cfc.oauth.oauthconsumer").init(
					sKey = config.ConsumerKey, 
					sSecret = config.ConsumerSecret)>
			<cfelse>
				<cfset var oReqSigMethodSHA = CreateObject("component", "cfc.oauth.oauthsignaturemethod_rsa_sha1")>
				<cfset var oConsumer = CreateObject("component", "cfc.oauth.oauthconsumer").init(
					sKey = config.ConsumerKey, 
					sSecret = config.ConsumerSecret,
					sPathToPrivateKey = config.PathToPrivateKey)>
			</cfif>

			
			<cfset var stDefault = StructNew()>
			<cfset stDefault["oauth_callback"] = config.CallbackBaseUrl & config.CallbackPath>

			<cfset oReq = CreateObject("component", "cfc.oauth.oauthrequest").fromConsumerAndToken(
				oConsumer = oConsumer,
				oToken = oToken,
				sHttpMethod = "GET",
				sHttpURL = config.ApiBaseUrl & config.RequestTokenPath,
				stParameters = stDefault)>
			<cfset oReq.signRequest(
				oSignatureMethod = oReqSigMethodSHA,
				oConsumer = oConsumer,
				oToken = oToken)>

			<!--- make requestToken call to Xero  --->
			<cfhttp url="#oREQ.getString()#" 
					method="GET" 
					result="tokenResponse"/>

			<!--- was an oauth_token returned in the response if its there--->
			<cfif findNoCase("oauth_token",tokenresponse.filecontent)>

				<!--- Build Authorize URL --->
				<cfset oResultAuth = CreateObject("component", "cfc.xero").authorize(
					sTokenResponse = tokenresponse.filecontent,
					sConsumerKey = config.ConsumerKey, 
					sConsumerSecret = config.ConsumerSecret,
					sCallbackURL = config.CallbackBaseUrl & config.CallbackPath,
					sAuthorizationEndpoint = config.AuthenticateUrl)>

				<cfset oResultRequest["url"] = oResultAuth["url"]>
			<cfelse>
				<cfset oResultRequest["content"] = tokenResponse.filecontent>
			</cfif>

		<cfreturn oResultRequest>
	</cffunction>


	<!--- attempt to build up an authorization URL from what was returned from the server --->
	<cffunction name="authorize" access="public" returntype="struct">
		<cfargument name="sTokenResponse" required="true" type="string" default="">

			<cfset var config = application.config>
			<cfset var oResultAuth = StructNew()>

			<cfloop list="#arguments.sTokenResponse#" index="elem" delimiters="&">  
				<cfset session.stToken[#listFirst(elem,"=")#] = #listLast(elem,"=")#>	
			</cfloop>  

			<cfset sClientToken = session.stToken["oauth_token"]>
			<cfset sClientTokenSecret = session.stToken["oauth_token_secret"]>

			<!--- you can add some additional parameters to the callback --->
			<cfset sCallbackURL = config.CallbackBaseUrl & config.CallbackPath & "?" &
				"key=" & config.ConsumerKey &
				"&" & "secret=" & config.ConsumerSecret &
				"&" & "token=" & sClientToken &
				"&" & "token_secret=" & sClientTokenSecret &
				"&" & "endpoint=" & config.AuthenticateUrl>

			<cfset sAuthURL = config.AuthenticateUrl & "?oauth_token=" & sClientToken & "&" & "oauth_callback=" & URLEncodedFormat(config.CallbackBaseUrl & config.CallbackPath) >

			<cfset oResultAuth["url"] = sAuthURL >

		<cfreturn oResultAuth>
	</cffunction>

	<!--- attempt to build the URL to swap the requestToken for an accessToken from the Xero server --->
	<cffunction name="accessToken" access="public" returntype="struct" output="true">
		<cfargument name="aCallbackParams" required="true" type="string" default="">
	
			<cfset var config = application.config>
			<cfset var stResult = StructNew()>
			<cfset var stCallbackResult = StructNew()>
			<cfset var oResultRequest = StructNew()>

			<!--- set up the parameters --->
			<cfloop list="#arguments.aCallbackParams#" index="elem" delimiters="&">  
				<cfset session.stCallbackResult[#listFirst(elem,"=")#] = #listLast(elem,"=")#>	
			</cfloop>  

			<cfset var oauthToken = session.stCallbackResult.oauth_token>
			<cfset var sVerifier =  session.stCallbackResult.oauth_verifier>

			<cfset var sRequestToken = session.stToken["oauth_token"]> <!--- returned after an request token call --->
			<cfset var sRequestTokenSecret = session.stToken["oauth_token_secret"]> <!--- returned after an request token call --->
				
			<cfset var oToken = CreateObject("component", "cfc.oauth.oauthtoken").init(
				sKey= sRequestToken,
				sSecret=sRequestTokenSecret)>

			<cfif config.AppType EQ "PUBLIC">
				<cfset var oReqSigMethodSHA = CreateObject("component", "cfc.oauth.oauthsignaturemethod_hmac_sha1")>
				<cfset var  oConsumer = CreateObject("component", "cfc.oauth.oauthconsumer").init(
					sKey = config.ConsumerKey, 
					sSecret = config.ConsumerSecret)>
			<cfelse>
				<cfset var oReqSigMethodSHA = CreateObject("component", "cfc.oauth.oauthsignaturemethod_rsa_sha1")>
				<cfset var oConsumer = CreateObject("component", "cfc.oauth.oauthconsumer").init(
					sKey = config.ConsumerKey, 
					sSecret = config.ConsumerSecret,
					sPathToPrivateKey = config.PathToPrivateKey)>
			</cfif>

			<cfset var stParameters = structNew()>
			<cfset var stParameters.oauth_verifier = sVerifier>

			<cfset var oReq = CreateObject("component", "cfc.oauth.oauthrequest").fromConsumerAndToken(
				oConsumer = oConsumer,
				oToken = oToken,
				sHttpMethod = "GET",
				sHttpURL = config.ApiBaseUrl & config.AccessTokenPath,
				stparameters= stParameters )>

			<cfset oReq.signRequest(
				oSignatureMethod = oReqSigMethodSHA,
				oConsumer = oConsumer,
				oToken = oToken)>

			<!--- make AccessToken call to Xero  --->
			<cfhttp url="#oREQ.getString()#" 
				method="GET" 
				result="tokenResponse"/>

			<!--- was an oauth_token returned in the response if its there save the new access token --->
			<cfif findNoCase("oauth_token",tokenresponse.filecontent)>
				<cfset session.stToken["timestamp"] = '#DateFormat(now(), "mmm-dd-yyyy")# #TimeFormat(now(), "hh:mm:ss")#' >
				<cfloop list="#tokenResponse.filecontent#" index="elem" delimiters="&">  
					<cfset session.stToken[#listFirst(elem,"=")#] = #listLast(elem,"=")#>	
				</cfloop>  

				<cfset oResultRequest["content"] = "success" >
			<cfelse>			
				<cfset oResultRequest["content"] = tokenResponse.filecontent >
			</cfif>

		<cfreturn oResultRequest>

	</cffunction>


	<!--- attempt to build up a requestData URL from the config details --->
	<cffunction name="requestData" access="public" returntype="struct">
		<cfargument name="sResourceEndpoint" required="true" type="string" default="">
		<cfargument name="sOAuthToken" required="false" type="string" default="">
		<cfargument name="sOAuthTokenSecret" required="false" type="string" default="">
		<cfargument name="stParameters" required="false" type="struct" default="">
		<cfargument name="sAccept" required="false" type="string" default="#application.config.json["Accept"]#">
		<cfargument name="sIfModifiedSince" required="false" type="string" default="">
		<cfargument name="sMethod" required="false" type="string" default="GET">
		<cfargument name="sBody" required="false" type="string" default="">
		<cfargument name="contentType" required="false" type="string" default="application/json">
		<cfargument name="debug" required="false" type="boolean" default="false">

			<cfset var config = application.config>
			<cfset var oResultRequest = StructNew()>

			<!--- set up the required objects including signature method--->
			<cfif config.AppType EQ "PUBLIC">	
				<cfset oReqSigMethodSHA = CreateObject("component", "cfc.oauth.oauthsignaturemethod_hmac_sha1")>
				<cfset oConsumer = CreateObject("component", "cfc.oauth.oauthconsumer").init(
					sKey = config.ConsumerKey, 
					sSecret = config.ConsumerSecret)>
			<cfelse>
				<cfset oReqSigMethodSHA = CreateObject("component", "cfc.oauth.oauthsignaturemethod_rsa_sha1")>
				<cfset oConsumer = CreateObject("component", "cfc.oauth.oauthconsumer").init(
					sKey = config.ConsumerKey, 
					sSecret = config.ConsumerSecret,
					sPathToPrivateKey = config.PathToPrivateKey)>
			</cfif>

			<cfif config.AppType EQ "PRIVATE">
				<cfset this.Token = config.ConsumerKey>
				<cfset this.TokenSecret = config.ConsumerSecret>
			<cfelse>
				<cfset this.Token = arguments.sOAuthToken>
				<cfset this.TokenSecret = arguments.sOAuthTokenSecret>
			</cfif>

			<cfset oToken = CreateObject("component", "cfc.oauth.oauthtoken").init(
					sKey = this.Token,
					sSecret = this.TokenSecret)>

			<cfset oReq = CreateObject("component", "cfc.oauth.oauthrequest").fromConsumerAndToken(
				oConsumer = oConsumer,
				oToken = oToken,
				sHttpMethod = arguments.sMethod,
				sHttpURL = arguments.sResourceEndpoint,
				stparameters= arguments.stParameters )>
				
			<cfset oReq.signRequest(
				oSignatureMethod = oReqSigMethodSHA,
				oConsumer = oConsumer,
				oToken = oToken)>

			<!--- Request data from Xero API --->
			<cfhttp 
				url="#oREQ.getString()#" 
				method= "#arguments.sMethod#" 
				result="tokenResponse" >
				<cfhttpparam type="header" name="accept" value="#arguments.sAccept#">
				<cfif len(arguments.sIfModifiedSince)>
					<cfhttpparam type="header" name="If-Modified-Since" value="#DateFormat(arguments.sIfModifiedSince," YYY-MM-DD")#T#TimeFormat(arguments.sIfModifiedSince,"HH:MM:SS")#">
				</cfif>
				<cfif len(arguments.sBody)>
					<cfhttpparam type="body" value="#trim(arguments.sBody)#">
				</cfif>
			</cfhttp>

		<cfset stReturn = structNew()>
		<cfif isXML(tokenResponse.Filecontent)>
			<cfset stReturn.response = ConvertXmlToStruct(tokenResponse.Filecontent,structNew())>
		<cfelse>
			<cfset stReturn.response = tokenResponse.Filecontent>
		</cfif>
		<cfreturn stReturn>
	</cffunction>

	<cffunction name="ConvertXmlToStruct" access="private" returntype="struct" output="true"
					hint="Parse raw XML response body into ColdFusion structs and arrays and return it.">
		<cfargument name="xmlNode" type="string" required="true" />
		<cfargument name="str" type="struct" required="true" />
		<!---Setup local variables for recurse: --->
		<cfset var i = 0 />
		<cfset var axml = arguments.xmlNode />
		<cfset var astr = arguments.str />
		<cfset var n = "" />
		<cfset var tmpContainer = "" />

		<cftry>
			<!---
			Strip out the tag prefixes. This will convert tags from the
			form of soap:nodeName to JUST nodeName. This works for both
			openning and closing tags.
			--->
			<cfset arguments.xmlNode = arguments.xmlNode.ReplaceAll(
			"(</?)(\w+:)",
			"$1"
			) />
			 
			<!---
			Remove all references to XML name spaces. These are node
			attributes that begin with "xmlns:".
			--->
			<cfset arguments.xmlNode = arguments.xmlNode.ReplaceAll(
			"xmlns(:\w+)?=""[^""]*""",
			""
			) />
			 
			<!---
			Remove all references to XML name spaces. These are node
			attributes that begin with "xsi:".
			--->
			<cfset arguments.xmlNode = arguments.xmlNode.ReplaceAll(
			"xsi(:\w+)?=""[^""]*""",
			""
			) />
			<cfcatch type="any"><!--- IGNORE ERRORS. JUST TRYING TO STRIP NAMESPACES WHERE APPROPRIATE ---></cfcatch>
		</cftry>
		
		<cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
		<cfset axml = axml[1] />
		<!--- For each children of context node: --->
		<cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
			<!--- Read XML node name without namespace: --->
			<cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
			<!--- If key with that name exists within output struct ... --->
			<cfif structKeyExists(astr, n)>
				<!--- ... and is not an array... --->
				<cfif not isArray(astr[n])>
					<!--- ... get this item into temp variable, ... --->
					<cfset tmpContainer = astr[n] />
					<!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
					<cfset astr[n] = arrayNew(1) />
					<!--- ... and reassing temp item as a first element of new array: --->
					<cfset astr[n][1] = tmpContainer />
				<cfelse>
					<!--- Item is already an array: --->
					
				</cfif>
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
						<!--- recurse call: get complex item: --->
						<cfset astr[n][arrayLen(astr[n])+1] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
					<cfelse>
						<!--- else: assign node value as last element of array: --->
						<cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
				</cfif>
			<cfelse>
				<!---
					This is not a struct. This may be first tag with some name.
					This may also be one and only tag with this name.
				--->
				<!---
						If context child node has child nodes (which means it will be complex type): --->
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
					<!--- recurse call: get complex item: --->
					<cfset astr[n] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
				<cfelse>
					<!--- else: assign node value as last element of array: --->
					<!--- if there are any attributes on this element--->
					<cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
						<!--- assign the text --->
						<cfset astr[n] = axml.XmlChildren[i].XmlText />
							<!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
						 <cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
						 <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
							 <cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
								 <!--- remove any namespace attributes--->
								<cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
							 </cfif>
						 </cfloop>
						 <!--- if there are any atributes left, append them to the response--->
						 <cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
							 <cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
						</cfif>
					<cfelse>
						 <cfset astr[n] = axml.XmlChildren[i].XmlText />
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- return struct: --->

		<cfreturn astr />
	</cffunction>

</cfcomponent>