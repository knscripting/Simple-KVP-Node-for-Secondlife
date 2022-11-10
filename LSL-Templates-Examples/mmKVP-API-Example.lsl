/*   
mmKVP API v01
This is the Initial release for the Simple KVP Node for Secondlife

This script can be used in different ways. As an single script in your project,
    A stand alone script in your object that responds to link_messages or listens providing
    data to the other scripts in your linkset or region.

    --Coming soon, when KVP on LinkSet is fully available in the grid, I'll write an example
    to pass information via that system. 

    Note: HTTP Requests are "asynchronous". Meaning if we make Three reaquests: 1, 2, 3
        They could be returned in a different order  2, 1, 3... 
        Keep this in mind when making link_message or listen calls to this script. 
        -See Examples below.

    Note: Only use ONE "include" of this API in your object otherwise weird issues.

    Note: debugMe is used liberally in the script to aid in debugging. When you release the API
        I recommend you only allow this script to kick back the more serious errors.
        -Node not online, Error 500s, 
        Ideally your calling main script handles any reporting to the user.

The API runs inline or listens on the defined channels below for a unique key, and a value
to read/write to an external node.js mongoDB store.
At this stage security is minimal and requires external configuration of a server/host of your choosing
see gitHub for optoins

https://github.com/knscripting/Simple-KVP-Node-for-Secondlife
2022-11-03 Kehf Nelson

Known Issues:
-Keep your mmValue size in mind. http requests have a max size of 16K. This is an LSL/Mono thing and can't be increased
-Keep your API Key secure to you.
-ALWAYS set your API script to no modify. 
-There's a hard limit to the number of requests you can make per user. 25 in 20 seconds. The API will try to mitigate this
    But be aware and plan ahead.


ToDo:
-Delete.New,Patch method, do we really need it?
-Retrieve MetaData?
-Retrieve a list of *like keys or searchable mmValue?
-KVP in linkset when available



*/

//!!!!! <- Find these comments, they are important

//!!!!! Required Settings
// http or https whatever you setup on your host

//apiKey MUST match what is set in .env on your mmKVP node

#define apiKey "SET_THIS_TO_Your_Hosts_API_KEY"
/*
The URL of your mmkVP node. 
https is not supported out of the box. Consider enabling a simple nginx https proxy in produciton
Using amazons EC2 free tier to a mongodb.com free tier is surprisingly quick. 
*/

#define nodeHOST "http://YOURHOST:8080/mmkvp/"

/* !!!!! Keep this secret!
Key Generator hash. 
A Unique Key for the Database. I recommend something like:
           (string)llGetOwner() + "#" + "-Reference Type-" + "#"-ProjectName-"
           Ex:
           123-123-12312312312-1231231#Player#My_First_KVP_HUD
           or
           231.137-35132423423-1774564#Monster#My_First_KVP_HUD
           
           That's all up to you and should be set to your needs

           !!!!! This api can retrieve ANY key in your DB. 
                Keep the forumation of your keyhash just as
                Secret as your API Key. 
*/
#define myKeyHash (string)llGetOwner()+"-MyProjectName" 
/*
llLinkMessage or Listen"channels" if used
!!!!! change these and keep them secret, currently the only security in place to prevent
"unauthorized" access to the contents of your DB. 
*/
//We'll listen for requests from other scripts via link_message on chanNumRequest
#define chanNumRequest 8675309 

//We'll respond to those reqests on a channel GREATER than chanNumResponse 
//   When sending a request especially from multiple scripts in your linkset
//   add a value to chanNumResponse 
//   ex   num = chanNumResponse + llGetLinkNumber() + some_other_unique_integer_assigned_to_each_script
#define chanNumResponse 8675310 
//!!!!! END SET VALUES


//Debugging
#define debugMe(msg)\
  llOwnerSay(msg);

/*
!!!!! Method Defines for easier HTTPRequest logic:
    1 2 3 are default, you can add more if you need them
    ex: #define SETUP 4    maybe is a special read to initialize the system
    You can also just use Integers. See mmQuery() and http_response()
*/
#define NEW 1
#define WRITE 2
#define READ 3

//Macros for headers based on C.R.U.D. options
#define headerPUT [HTTP_BODY_MAXLENGTH,16384, HTTP_METHOD,"PUT",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerPOST [HTTP_BODY_MAXLENGTH,16384, HTTP_METHOD,"POST",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerGET [HTTP_BODY_MAXLENGTH,16384, HTTP_METHOD,"GET",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]
#define headerDELETE [HTTP_BODY_MAXLENGTH,16384, HTTP_METHOD,"DELETE",HTTP_MIMETYPE, "application/x-www-form-urlencoded"]

//Macro Function to parse mmValue from response
#define RETURNmmValue result=llJsonGetValue(body,["mmValue"])

/* !!!!! mmQuery(integer mmMethod, integer resHandle, string mmKey, string mmValue) and helper lists and integers

Combined Read Write Function that populates mmKVPQueue for http_response() handling

mmKVPOverRun is a UnixTimeStamp meant as a non-timered cooldown to handle overruns or a failed llHTTPRequest -- Janky I know.

mmKVPQueue is a list of http_request KEYs, and a Response-handle-Flag.  see http_response()

integer mmMethod is our READ WRITE DELETE CREATE  and are #defined macros above  1 2 3  or your own Integer
integer resHandle is a flag passed to http_response on how to handle the expected output associated with a given request. READ and WRITE are default
    Any other handles you'll need to write following the examples in the http_response() state
    often mmMethod and resHandle are the same.
    
mmKey and mmValue are the key to read/write and the value to write or read.  
    mmKey may not be NULL. mmValue may be Null. 
    !!!!! By default we won't check for that. 

Ex: mmQuery(READ, READ, myKey, "" )   
    -- to perform a Read with default response handling
    mmQuery(WRITE, WRITE, myKey, myValue)  
    -- to perform a write with default reponse handing
    mmQuery(READ, 666, "Special-Startup-Key-For-Init-Data", "")  
    -- performs a READ then http_response() will need a handle for STARTUP you will need to code response handle 666 in http_response
    mmQuery(WRITE, 21831, myKey, myValue)   
    -- Performs a write but uses a special handle  21831 (You code it in http_response) for the returned mmValue from mmKVP

*/   
integer mmKVPOverRun = 0 ; //This is a lock to prevent http Overruns
list mmKVPQueue = [] ; //Strided list of all the queries and how they should be handled.  Each valid mmQuery adds to this list, http_response deletes the assicated key from it.
mmQuery(integer mmMethod, integer resHandle, string mmKey, string mmValue) {
    
    key httpReqAttempt ;
    
    if (mmKVPOverRun > llGetUnixTime()) {
        debugMe("HTTP_REQUEST Overrun Protection, Request Dropped!") ;
        //return NULL_KEY ;
    } else     
    if (mmMethod == READ) {
        httpReqAttempt=llHTTPRequest(nodeHOST+"mmRead/",headerPOST,"mmKey="+mmKey+"&apiKey="+apiKey)  ;  
    } else
    if (mmMethod == WRITE) {
        httpReqAttempt=llHTTPRequest(nodeHOST+"mmWrite/",headerPUT,"mmKey="+mmKey+"&mmValue="+mmValue+"&apiKey="+apiKey)   ; 
    }    
    //Check if our request is valid if so, add this request to the processing queue
    if (httpReqAttempt != NULL_KEY) {
        mmKVPQueue += [ httpReqAttempt , resHandle ] ;
    } else {
        mmKVPOverRun = llGetUnixTime() + 5 ;
        debugMe("HTTP_REQUEST Failed, No Keyspace Available, Request Dropped");
    }           
}

string myValue ; 
string myKey ;

///////////// Memory Management Helper Functions - Not Required
#define memoryLimit(x) \
 llSetMemoryLimit( (integer)((float)llGetUsedMemory()*x) ) 

#define memoryStats()\
  llOwnerSay("Memory Stats: " + "\n  -Used: "+(string)llGetUsedMemory() + "\n  -Free: "+(string)llGetFreeMemory())  
/////////////
default
{
    /* !!!!!

    listen() link_message() touch_start() 
    
    Are included for demo and instructional purposes, they are situational to your requirements.

    touch_start() is included for testing and demo purposes

    //optional Process Requests that come in via a Listen
    listen (integer chan, string name, key id, string msg)
    { 
        //list msgData = llParseString2List(msg,["*"],[]);
        // !!!!! You need to figure out how to pass the required
        // arguments for mmQuery   
    }
    */

    /* 
        Here's an example of how to handle mmKVP requests via link_messages

        If we are requesting via a link_message we'll assume you want to receive the result
        via link_message.  see http_response()
        
        Using the link_message structure we'll break a request and track a response using the "key id" 
        and "integer num"

        Expect msg = mmKey $$ mmValue  --The body of our request which we'll turn msg into a list removing $$
        Expect id = Method $$ ResHandler/CallBackChannel   --Also a list removing $$
    */
    //link_message(integer link, integer num, string msg, key id)
    //{     
        //if( num == chanNumRequest) { //Take all inbound requests on #define above
        //    
            //debugMe("API -Received from Link -" + 
            //    "\nLINK: "+(string)link +
            //    "\nNUM:  "+(string)num  +
            //    "\nKEY:  "+(string)id +
            //    "\nMSG:  "+(string)msg );
            
            //  !!!!! The important part.  
            //    We'll split the string into lists
            //    Then pass the the elements into mmQuery
                
            //list mmKeyValue = llParseString2List( msg, ["$$"], [] ) ;
            //list mmCallResMethod = llParseString2List( id, ["$$"], [] ); 
            
            //mmQuery(
            //    llList2Integer( mmCallResMethod, 0) ,
            //    llList2Integer( mmCallResMethod, 1) ,
            //    llList2String(mmKeyValue, 0) ,
            //    llList2String(mmKeyValue, 1) );
            
        //} //chanNumRequest             
    //}//link_message

    // !!!! For Demo purposes
    touch_start(integer total_number)
    {
        //Simple Testing 
        myValue = llGetUnixTime() ;
        debugMe("Trying to Query DB with-\nmmKey: "+myKey 
                + "\nmmValue: "+myValue);
        
        //mmQuery(WRITE, WRITE, myKey, myValue); 
        mmQuery( READ, READ, myKey, "");
    } //Touch
    
    // !!!!! API Required
    http_response(key request_id, integer status, list metadata, string body)
    {   
        //debugMe("Queue Before: "+llDumpList2String(mmKVPQueue, "$") );
        //debugMe("API - length: "+(string)llStringLength(body)+ "\nstatus: "+(string)status +"\nbody: "+body);  

        //Find the request_id match in mmKVPQueue
        integer idx = llListFindList(mmKVPQueue, [request_id]) ;
        
        if (idx >= 0) { // -1 if not found, do nothing
        
            integer resHandle = llList2Integer(mmKVPQueue,idx+1) ; //Get the handler flag for the found key
            string result = "" ;  //What body is recorded into
            mmKVPQueue = llDeleteSubList(mmKVPQueue, idx, idx+1 ) ; //Delete the matching key and flag from the mmKVPQueue list
            
            // If you are using the API in a link_message or listen scenario. Handling status errors should be moved outside of the API
            // Report the error via resHandler and let those scripts figure it out.
            
            //Start handling responses by status.
            if (status == 200){  //mmKVP returns status 200, that means the query "worked" or didn't throw an error
                //If the body is a Json of no length, re-write and return NULL
                if (llStringLength(body) <= 4 ) { 
                    body = "{\"mmValue\": \"NULL\"}" ;
                }
             
                // Rrespone Handlers                   
                if (resHandle == WRITE ){
                    if (body == "NULL"){
                        result = "ERROR - Unable to Write";
                    }else {
                        RETURNmmValue ; //See #define above
                    }
                } // WRITE
                else if (resHandle == READ ){
                    if (body == "NULL"){
                        result = "ERROR, No Matching mmKey";
                    }else {
                        RETURNmmValue ; //See #define above
                    }
                } else if (resHandle >= chanNumResponse ) {  
                    /* !!!!!!
                        Let's say any other resHandle greater than chanNumResponse is a "channel" to respond upon.
                        Let the call script handle the output and potential errors.                       
                    */
                    RETURNmmValue ; //See #define above
                    llMessageLinked(LINK_SET, resHandle, result, (string)status);
                } else {
                    result = "ERROR, Bad resHandle" ; //Catchall
                }
                /*
                !!!!!
                Follow the same else if (methodFlag == Integer) for custom repsonse handlers. 
                If you are using linkMessage or Listens, you can hadle this logic in the calling
                script. 
                !!!!!  
                */
            } //200
            else if ( status >= 500)
            {
                // !!!!! Do something, or not, if the key is not found
                //No Key Found, create a record
                //debugMe("API - No Matching Key, Creating it");   // Optional
                //mmQuery(WRITE, WRITE, myKey, "Init Value"); //Since there is no key, take the liberty of making one
                //llSleep(1.5); //Let's just sleep for good measure
                
                // ex. llLinkMessage(LINK_SET, resHandle, "ERROR, 500", (string)status);    
            } // 500
            else if (status >= 400)
            {
                result = "ERROR: "+(string)status ;
                // ex. llLinkMessage(LINK_SET, resHandle, "ERROR, 400", (string)status);
                //debugMe("API - length: "+(string)llStringLength(body)+ "\nstatus: "+(string)status +"\nbody: "+body);    
            } // 400
            else if (status >= 300 )
            {
                result = "ERROR: "+(string)status ;
                // ex. llLinkMessage(LINK_SET, resHandle, "ERROR, 300", (string)status);
            } //300            
        }//if (idx >= 0)
    } // http_response()
   
    //state_entry() is mostly optional.. 
    state_entry()
    {
        //myKey = myKeyHash; //Optional - Can be Generate a default key for this Project

        //debugMe("On touch I will Read - \nmmKey: "+myKey 
        //        + "\nmmValue: "+myValue);
    
        //memoryStats() ;  // !!!!! Optional - Displays memory usage.           
   
    } //state_entry
} //Default
