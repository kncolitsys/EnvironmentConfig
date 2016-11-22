<cfcomponent displayname="BeanMaker" hint="Use to create a ColdFusion Class (CFC) based on a structure of properties" output="true" extends="Object"  >

			<!---
			*************************************************************************
			init()
			************************************************************************
			--->
		<cffunction name="init" returntype="BeanMaker" output="false" hint="Class constructor" access="package">

			<cfreturn this />
		</cffunction>

			<!---
			********************************************************************************
			createBean()
			Hint: I create the bean and store it in a string
			********************************************************************************
			--->
		<cffunction name="createBean" output="true" access="package" returntype="struct" hint="Creatse and writes the bean file to the specified path">
			<cfargument name="stProperties" type="struct" required="true" hint="structure of properties to be used for the Bean" />
			<cfargument name="objPathDotNotation" type="string" required="false" default="model.GlobalConfig" hint="Dot path notation to destination of the CFC being generated. The destination package (folder) must exist." />
			<cfargument name="setterAccess" type="string" required="false" default="public" hint="A string value to determine the access to the setter methods. See coldfusion documentation for Function access property options."/>
			<cfscript>
				var stReturn 	= structNew();
				var ixProperty = '';
				stReturn.success = true;

				arguments.objPathDotNotation = fixObjectPath( arguments.objPathDotNotation,'/','.');
				if(!listFindNoCase("public,private,package",arguments.setterAccess))
					arguments.setterAccess = "public";
			</cfscript>
			<cftry>
				<cfsavecontent variable="stReturn.beanString"><cfoutput>

<%cfcomponent displayname="#listLast(arguments.objPathDotNotation, '.')#" hint="Application properties bean" output="false"%>
<cfloop collection="#arguments.stProperties#" item="ixProperty">#indent(2)#<%cfproperty name="#ixProperty#" type="#getArgumentType(arguments.stProperties[ixProperty])#" required="false" default=""  /%>
</cfloop>
		<%!---
		*************************************************************************
		init()
		************************************************************************
		---%>
	<%cffunction name="init" returntype="#listLast(arguments.objPathDotNotation, '.')#" output="false" hint="I initialize the bean"%>
<cfloop collection="#arguments.stProperties#" item="ixProperty">#indent(3)#<%cfargument name="#ixProperty#" type="#getArgumentType(arguments.stProperties[ixProperty])#" required="false" default=""  /%>
</cfloop>
			<%!--- initialize variables ---%>
		<%cfscript%>
<cfloop collection="#arguments.stProperties#" item="ixProperty">#indent(4)#set#uCase(left(ixProperty,1))##right(ixProperty,len(ixProperty)-1)#(arguments.#ixProperty#);
</cfloop>#indent(3)#<%/cfscript%>
		<%cfreturn this /%>
	<%/cffunction%>
		<%!--- setters ---%>
<cfloop collection="#arguments.stProperties#" item="ixProperty">
		<%!--- set#uCase(left(ixProperty,1))##right(ixProperty,len(ixProperty)-1)#(#getArgumentType(arguments.stProperties[ixProperty])#) ---%>
	<%cffunction name="set#uCase(left(ixProperty,1))##right(ixProperty,len(ixProperty)-1)#" access="#arguments.setterAccess#" returntype="void" hint="I set #ixProperty# variable" output="false"%>
		<%cfargument name="value" type="#getArgumentType(arguments.stProperties[ixProperty])#" required="true" /%>
		<%cfset variables.inst.#ixProperty# = arguments.value /%>
	<%/cffunction%>

		<%!--- get#uCase(left(ixProperty,1))##right(ixProperty,len(ixProperty)-1)#() ---%>
	<%cffunction name="get#uCase(left(ixProperty,1))##right(ixProperty,len(ixProperty)-1)#" access="public" returntype="#getArgumentType(arguments.stProperties[ixProperty])#" hint="I get #ixProperty# variable" output="false"%>
		<%cfreturn variables.inst.#ixProperty#  /%>
	<%/cffunction%>
</cfloop>
		<%!--- getMemento() ---%>
	<%cffunction name="getMemento" access="public" returntype="struct" hint="I get Memento" output="false"%>
		<%cfreturn variables.inst /%>
	<%/cffunction%>

		<%!--- hasProperty() ---%>
	<%cffunction name="hasProperty" access="public" returntype="boolean" hint="Returns true if the bean has the specified property, false otherwise" output="false"%>
		<%cfargument name="propertyName" type="String" required="true" /%>
		<%cfscript%>
			if(structKeyExists(variables.inst, arguments.propertyName))
				return true;
			else
				return false;
		<%/cfscript%>	
	<%/cffunction%>
<%/cfcomponent%></cfoutput>
				</cfsavecontent>
				<cfscript>
					stReturn.beanString = fixBeanString(trim(replaceList(stReturn.beanString,"<%,%>","<,>")));
					writeBeanToFile( stReturn.beanString, arguments.objPathDotNotation );
				</cfscript>
				<cfcatch type="any">
					<cfscript>
						if(listFirst(cfcatch.type,".") == 'ec')
							rethrow;
						eThrow("Error creating Bean file","ec.CreateBean");
						writeDump(var:cfcatch,abort:true);
					</cfscript>
				</cfcatch>
			</cftry>
			<cfreturn stReturn />
		</cffunction>

			<!---
			********************************************************************************
			writeBeanToFile()
			Author: Roland Lopez - Date: 1/24/2008
			Hint: I write the bean into a cfc
			********************************************************************************
			--->
		<cffunction name="writeBeanToFile" output="false" access="package" returntype="struct" hint="I write the bean into a cfc">
			<cfargument name="beanString" type="string" required="true"  />
			<cfargument name="fullObjectPath" type="string" required="false" default="model.GlobalConfig"  />
			<cfscript>
				var stReturn 	= structNew();
				var filePath	= expandPath( fixObjectPath(arguments.fullObjectPath) ) & ".cfc";
				var dirPath 	= filePath;
				var osFileSep	= createObject("java", "java.lang.System").getProperty("file.separator");
				dirPath = listDeleteAt(dirPath,listLen(dirPath,osFileSep),osFileSep);
				stReturn.success 	= true;
			</cfscript>
			<cftry>
				<cfif !directoryExists(dirPath)>
					<cfthrow type="ec.DirectoryNotFound" message="The ColdFusion class path provided:<br />#dirPath# <br />to the BeanMaker does not exist. CFC could not be created. Ensure the path provided exists before executing the method." />
				</cfif>
				<cfdump var="Writing Bean file to: #filePath#" output="console" />
				<cffile action="write" file="#filePath#" output="#arguments.beanString#" />
				
				<cfcatch type="ec.DirectoryNotFound">
					<cfrethrow>
				</cfcatch>
				<cfcatch type="any">
					<cfscript>
						stReturn.success 		= false;
						stReturn.errorDetails 	= cfcatch;
					</cfscript>
					<cfthrow type="ec.FileWrite" message="Unable to write CF class to #filePath#" />
				</cfcatch>
			</cftry>

			<cfreturn stReturn />
		</cffunction>

			<!---
			********************************************************************************
			indent()
			Author: Roland Lopez - Date: 1/24/2008
			Hint: inserts tab
			********************************************************************************
			--->
		<cffunction name="indent" output="false" access="private" returntype="string" hint="Returns tabs in ascii. Amount depends on the tabsQty input parameter.">
			<cfargument name="tabsQty" type="numeric" required="false" default="1" hint="Numeric value to determine the amount of tabs returned. Default value 1."/>
			<cfscript>
				var sTabs 	= '';
				var ixQty = 1;
				for(ixQty; ixQty < arguments.tabsQty; ixQty++)
					sTabs = sTabs & chr(9);
			</cfscript>
			<cfreturn sTabs />
		</cffunction>

			<!---
			********************************************************************************
			fixBeanString()
			Author: Roland Lopez - Date: 2/4/2008
			Hint: I fix the bean string dymmy characters
			********************************************************************************
			--->
		<cffunction name="fixBeanString" output="false" access="private" returntype="string" hint="Fixes the bean string dymmy characters. It Replaces <% and %> with < and > respectively.">
			<cfargument name="stringToFix" type="string" required="true"  />
			<cfscript>
				return trim(replaceList(arguments.stringToFix,"<%,%>","<,>"));
			</cfscript>
		</cffunction>

			<!---
			********************************************************************************
			fixObjectPath()
			Author: Roland Lopez - Date: 2/4/2008
			Hint: I fix the objectPath format
			********************************************************************************
			--->
		<cffunction name="fixObjectPath" output="false" access="private" returntype="string" hint="Fixes the objectPath format by replacing . (dots) with / (forward slashes) ">
			<cfargument name="stringToFix" type="string" required="true"  />
			<cfargument name="fromNotation" type="string" required="false" default="."/>
			<cfargument name="toNotation" type="string" required="false" default="/" />
			<cfscript>
				var sStartElement = '/';
				if(fromNotation eq '/')
					sStartElement = ''; 
				return  sStartElement & trim(replace(arguments.stringToFix,arguments.fromNotation,arguments.toNotation,'all'));
			</cfscript>
		</cffunction>

			<!---
			********************************************************************************
			getArgumentType()
			Hint: I check the argument's type and return the type as a string
			********************************************************************************
			--->
		<cffunction name="getArgumentType" output="false" access="private" returntype="string" hint="I check the argument's type and return the type as a string. Checks simple values to determine the apropriate CF DataType. If value can't be determined, it defaults to String.">
			<cfargument name="argumentToCheck" type="any" required="true"  />
			<cfscript>
				var sArgType = "string";

				if(isNumeric( arguments.argumentToCheck ))
					sArgType = "numeric";
				else if(isBoolean( arguments.argumentToCheck ))
					sArgType = "boolean";
				else if(isStruct(arguments.argumentToCheck))
					sArgType = "struct";
				else if(isValid( "UUID", arguments.argumentToCheck ))
					sArgType = "UUID";
				else if(isDate( arguments.argumentToCheck ))
					sArgType = "date";
				return sArgType;
			</cfscript>
		</cffunction>

</cfcomponent>