//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// SET THESE VALUES
//
//This is how your script with generate a unique Key. you have all sorts of options here. I recommend something with
//the user's/thing's OwnerKey or CreatorKey Plus a string Identifier for the Project, 
//You can even llSHA256String(some+unique+bunch+of+strings) for futher uniqueness. 
//Whatever you want to do to make a key unique in your project's Database.  
 #define myKeyHash (string)llGetOwner()+"-Project-Test-API" 

// !!! Set these to something "secure" as of version 1 this is the best I have for in SL script "security" 
#define chanNumRequest 8675309
#define chanNumResponse 8675310

//!!!EndSet 
/*   

Testing mmKVP API 
Touch to set myKey Value using LinkMessage and mmkvp-API

Feel free to contribute and share.

https://github.com/knscripting/Simple-KVP-Node-for-Secondlife
2022-10-25 Kehf Nelson

*/



/////Helper Macros
//Memory management
#define memoryLimit(x) \
 llSetMemoryLimit( (integer)((float)llGetUsedMemory()*x) );

#define memoryStats()\
  llOwnerSay("Memory Stats: " + "\n  -Used: "+(string)llGetUsedMemory() + "\n  -Free: "+(string)llGetFreeMemory() ); 

//Simple Debugging
#define debugMe(msg)\
  llOwnerSay(msg);    

//Method Defines for easier HTTPRequest logic:
#define NEW 1
#define WRITE 3
#define READ 4

string myKey = "" ; //what our unique Key will be
string myValue = ""; //The value that will be stored and referenced by myKey


string myResponse = ""; //The string returned from the Query via link_message below
integer responseFlag =0 ; //how to process the query's associated response

//This is our READ WRITE etc function It requies a methodFlag, your key and what value you want to set
mmQuery(integer methodFlag, string mmKey, string mmValue)
{
    //string methodAndKey = (string)methodFlag+"$$"+mmKey ;
     /*
      
        methodFlag is the types of queries you intend to make:            
            method 1: NEW - Will return the mmValue of mmKey, if the node is online and the mmKey Exists, Or
                It will create the mmKey:mmValue pair and return that. Or it will timeout if the node is not online 
            method 2: WRITE - Updates the mmValue of mmKey assuming mmKey exists and returns the
                    updated data, write-then-read, your script needs
                    to check for that eventuality and if the record does not exist. 
            method 3: READ- find and return a string of the mmValue of the mmKey if it exists, or it will return null 
                  
        mmKey = A Unique Key for the Database. I recommend something like:
            (string)llGetOwner() + "#" + "Reference Type" + "#"ProjectName"
            Ex:
            123-123-12312312312-1231231#Player#My_First_KVP_HUD
            or
            231.137-35132423423-1774564#Monster#My_First_KVP_HUD
            
            That's completely optional and should be set to your needs
            
        mmValue = The data you want to store or update or create:
            Also a string, and is limited to the amount of data you can upload in a
            packet's body. 2048 characters should be safe, 
            
            The total amount is limited to the memory of the scripts in your object
            The length of your key + length of your data           
     */
    //responseFlag = methodFlag;   
    llMessageLinked(LINK_THIS, chanNumRequest, mmValue,(string)methodFlag+"$$"+mmKey );
}

default
{


    link_message(integer link, integer num, string msg, key id)
    {
        if (num == chanNumResponse ){
            debugMe("mmkvp response:\n\n"+msg);
            llSetText(msg,<0,1,0>,1.0);
            //
            // Response handling here
            //
            //list msgData = llParseString2List(msg,["$"],[]);
            myResponse = msg;
            
            
            /*!! Response Handler 
            If the returning Value is NULL that means an value doesn't exist for that key
            Or There is possibly an error. 
            Handle for all contingenies
            */
            if (myResponse == "NULL"){
                myValue="Set Because No Record Exists"+(string)llGetUnixTime();
                mmQuery(WRITE,myKey,myValue);
            }else {
                myValue = myResponse ;
            }
        }
    }

    touch_start(integer total_number)
    {
        llSetText("",<0,0,0>,0.0);
        //llTriggerSound("291cdf40-70a9-5820-9745-b517e0930dcd",0.25);
    
         //URL = URL + mmKvpRoute;
         //http_request_id = llHTTPRequest(URL, headers, req_body);     
         myValue = (string)llGetUnixTime();
         //mmQuery(INIT,myKey,"");               
         //mmQuery(READ,myKey,"");         
         mmQuery(WRITE,myKey,myValue);
         //mmQuery(CREATE,myKey,myValue);
         //llSleep(1);
         //mmQuery(READ,myKey,"");
    }
    
    state_entry()
    {
        myKey=myKeyHash ;//Might as well make a unique key at the start. 
        
        mmQuery(READ,myKey,""); //check if the mmkvp node is listening and return saved data
        
        memoryLimit(2.5) ; //could cause issues with big return values - default 1.5* mem
        memoryStats();
    }
}
