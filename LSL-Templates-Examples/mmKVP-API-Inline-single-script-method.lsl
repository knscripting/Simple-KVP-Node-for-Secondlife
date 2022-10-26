/* mmKVP inline configuration https://github.com/knscripting/Simple-KVP-Node-for-Secondlife

This script does nothing at the moment, it's a template so you can make your own
Unlike the llLinkMessage version of the API, this is a single stand alone method.

Consider this a template to build a functional script from.


// !!!!!! Required Settings

 The URL of your mmkVP node. 
 https is not supported out of the box. Consider enabling a simple nginx https proxy in produciton
 Using amazons EC2 free tier to a mongodb.com free tier is surprisingly quick. 
*/
#define nodeHOST "http://mynodelittlenode.com:8080/mmkvp/"

/*
 Key Generator hash. 
 A Unique Key for the Database. I recommend something like:
            (string)llGetOwner() + "#" + "Reference Type" + "#"ProjectName"
            Ex:
            123-123-12312312312-1231231#Player#My_First_KVP_HUD
            or
            231.137-35132423423-1774564#Monster#My_First_KVP_HUD
            
            That's completely optional and should be set to your needs
*/

#define myKeyHash (string)llGetOwner()+"-MyProject" 


// !!!!!! End Required Settings see http_response state below

//Macros to make code readability easier
#define NEW 1
#define WRITE 2
#define READ 3

/*
llLinkMessage "channels" if used
!!! change these and keep them secret, currently the only security in place to prevent
"unauthorized" access to the contents of your DB. 
*/
#define chanNumRequest 8675309
#define chanNumResponse 8675310

//Macros for headers based on C.R.U.D. options
#define headerPUT [HTTP_METHOD,"PUT",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerPOST [HTTP_METHOD,"POST",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerGET [HTTP_METHOD,"GET",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerDELETE [HTTP_METHOD,"DELETE",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]

//Macro Function to parse mmValue from response
#define RETURNmmValue result=llJsonGetValue(body,["mmValue"])

//Macro Function that generates and sends the http_request for a WRITE
#define mmWrite(mmKey, mmValue) \
    methodFlag=WRITE; \
    http_request_id=llHTTPRequest(nodeHOST+"mmWrite/",headerPUT,"mmKey="+mmKey+"&mmValue="+mmValue) 

//Macro Function that generates and sends the http_request for a READ
#define mmRead(mmKey) \
    methodFlag=READ ;\
    http_request_id=llHTTPRequest(nodeHOST+"mmRead/",headerPOST,"mmKey="+mmKey)

key http_request_id; 
integer methodFlag ; //Used to parse requests and responses
integer responseFlag =0 ; //how to process the query's associated response
string myKey = "" ; //what our unique Key will be
string myValue = ""; //The value that will be stored and referenced by myKey Or the Default Value
string myResponse = ""; //The string returned from the Query via link_message below
 
//// End of mmKVP API inline configuration 

default
{

    state_entry() {
       
        myKey = myKeyHash; //Generates a unique Key per the hash above
        mmRead(myKey); //Attempts to read data from the database using that key, consider this an initialization 
    }

//  !!!!!!  Required! Adjust for your needs
    http_response(key request_id, integer status, list metadata, string body){      
        if (request_id == http_request_id){
            string result = "" ;  //What body recorded into
            //debugMe("JXStrip - body/length: "+body + " "+(string)llStringLength(body)+ "\nstatus: "+(string)status);
            
            if (status == 200){
                //If the body is a Json of no length there is no record or some other problem
                if (llStringLength(body) <= 4 ) { 
                 // Optional, Create a record if it doesn't exist:
                    body="NULL";
                }
                  
                if (methodFlag == NEW ){
                   RETURNmmValue;
                }
                else if (methodFlag == WRITE ){
                    if (body == "NULL"){
                        result = "ERROR - Unable to Write";
                    }else {
                        RETURNmmValue ;
                    }
                }
                else if (methodFlag == READ ){
                    if (body == "NULL"){
                        result = "ERROR, No Matching mmKey";
                        // Optional, Create a record if it doesn't exist:
                        mmWrite(myKey,myValue) ;
                    }else {
                        RETURNmmValue ;
                    }
                }
                
                //mmKVP Sets the script flags per resonse from mmKVP
                list myValueList = llParseStringKeepNulls(result, ["$"],[]);
                
                //// !!!! Do something with the returned results here 
                
            } //200
            else if (status >= 300 ){
                result = "ERROR: "+(string)status ;   
            } //300
        
            methodFlag = 0;
            //debugMe("JXStrip Raw - result: "+result) ;

        }//if (request_id == http_request_id)
    }   
    
}