//!!!!! Required Settings
// http or https whatever you setup on your host

//apiKey MUST match what is .env on your mmKVP node
#define apiKey "ThisIsMyAPIKey" 
/*
The URL of your mmkVP node. 
https is not supported out of the box. Consider enabling a simple nginx https proxy in produciton
Using amazons EC2 free tier to a mongodb.com free tier is surprisingly quick. 
*/
#define nodeHOST "http://myNodeIPorFQDN.mine:PORT/mmkvp/"

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
/*
llLinkMessage "channels" if used
!!! change these and keep them secret, currently the only security in place to prevent
"unauthorized" access to the contents of your DB. 
*/
#define chanNumRequest 8675309
#define chanNumResponse 8675310

//!!!!! END SET VALUES

/*   

mmKVP API v01 LinkMessage

This is the Initial release for the Simple KVP Node for Secondlife
The API listens on the defined channels below for a unique key, and a value
to read/write to an external node.js mongoDB store.

At this stage security is minimal and requires external configuration of a server/host of your choosing
see gitHub for options


There are currently two "defined functions", Macros in our case,
mmWrite() and mmRead() fairly obvious here what the intent of each is. 

- mmWrite(string mmKey, string mmKey) takes two string arguments the UNIQUE Key to reference in the DB and the value to 
    assign that Key.  IF the Key does not exist it will be created. In either case the "function" will return the 
    new value assigned. 
    
- mmRead(string mmKey) takes on string argument and returns the value of that item in the DB. or it Returns NULL

Feel free to contribute and share.

https://github.com/knscripting/Simple-KVP-Node-for-Secondlife
2022-10-25 Kehf Nelson

ToDo:

-Delete method, do we really need it?
-Better error handling
-Some form of security?  cors, Hashing of content?

*/

//Debugging
#define debugMe(msg)\
  llOwnerSay(msg);

//Method Defines for easier HTTPRequest logic:
#define NEW 1
#define WRITE 2
#define READ 3

//Macros for headers based on C.R.U.D. options
#define headerPUT [HTTP_BODY_MAXLENGTH, 16384, HTTP_METHOD,"PUT",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerPOST [HTTP_BODY_MAXLENGTH, 16384, HTTP_METHOD,"POST",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerGET [HTTP_BODY_MAXLENGTH, 16384, HTTP_METHOD,"GET",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerDELETE [HTTP_BODY_MAXLENGTH, 16384, HTTP_METHOD,"DELETE",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]

//Macro Function to parse mmValue from response
#define RETURNmmValue result=llJsonGetValue(body,["mmValue"])

//Macro Function that generates and sends the http_request for a WRITE
#define mmWrite(mmKey, mmValue) \
    methodFlag=WRITE; \
    http_request_id=llHTTPRequest(nodeHOST+"mmWrite/",headerPUT,"mmKey="+mmKey+"&mmValue="+mmValue+"&apiKey="+apiKey) 

//Macro Function that generates and sends the http_request for a READ
#define mmRead(mmKey) \
    methodFlag=READ ;\
    http_request_id=llHTTPRequest(nodeHOST+"mmRead/",headerPOST,"mmKey="+mmKey+"&apiKey="+apiKey)

key http_request_id;
integer routeFlag ; 
integer methodFlag ; //Used to parse requests and responses
/// !!! End of mmKVP API


default
{
    state_entry()
    {

    }

    //Listens for calls from the other scripts to process to your node
    link_message(integer sender_num, integer num, string mmValue, key mmMethodAndKey)
    {
        
        if ( num == chanNumRequest){
            methodFlag = llList2Integer(llParseString2List(mmMethodAndKey, ["$$"], []),0)  ;
            string mmKey = llList2String(llParseString2List(mmMethodAndKey, ["$$"], []),1)  ;
            
            if (methodFlag == WRITE ){
                mmWrite(mmKey, mmValue);
            }
            else  if (methodFlag == READ ){
                mmRead(mmKey);
            }
            else if (methodFlag == NEW ){
                mmWrite(mmKey, mmValue);
            }
            else{
                debugMe("API Error - Bad methodFlag, no query Made\nflag:" + (string)methodFlag + "\nmmKey: "+mmKey + "\nmmValue: "+mmValue);
            }  
        }
    }
    
    //http Response handler. 
    http_response(key request_id, integer status, list metadata, string body)
    {      
        if (request_id == http_request_id)
        {
            string result = "" ;  //What body recorded into
            //debugMe("API - body/lenth: "+body + " "+(string)llStringLength(body)+ "\nstatus: "+(string)status);
            
            if (status == 200){
                //If the body is a Json of no length, re-write and return NULL
                if (llStringLength(body) <= 4 ) { 
                body = "{\"mmValue\": \"NULL\"}" ;
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
                    }else {
                        RETURNmmValue ;
                    }
                }
            } //200
            else if (status >= 300 ){
                result = "ERROR: "+(string)status ;   
            } //300
        
            methodFlag = 0;
            //debugMe("API Raw - result: "+result) ;
            llMessageLinked(LINK_THIS, chanNumResponse, result, "");
        }//if (request_id == http_request_id)
    }
}
