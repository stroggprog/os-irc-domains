/*
Copyright (c) 2025 Zen Drako @ moss.mossgrid.uk (not an email address)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* 
List of OSSL Functions used:
============================
Total OSSL Functions used: 0
*/

integer LNK_MSG_RECV  = -4247894;
integer LNK_MSG_SEND  = -4247895;
integer LNK_MSG_RESET = -4247896;

// options are [ to_region, to_address ]
list defaultOptions = [ "*", "*" ];
integer MSG_OPTS_REGION     = 0;
integer MSG_OPTS_ADDRESS    = 1;

// msg sections
integer MSG_TYPE = 0;
integer MSG_MSG = 1;
integer MSG_DATA = 2;

string dataSeparator = ";;";

relay( string message, list who ){
    if( who == [] ) who = defaultOptions;
    llMessageLinked( LINK_THIS, LNK_MSG_SEND, message, llList2CSV(who) );
}

handleMessage( string msg, string senderDetails ){
    // senderDetails = [from-region, from-address]
    list details = llParseStringKeepNulls( msg, ["::"], [] );
    string msgType = llList2String( details, MSG_TYPE );
    string msgMsg = llList2String( details, MSG_MSG );
    list data = llParseStringKeepNulls( llList2String( details, MSG_DATA ), [dataSeparator], [] );

    if( msgType == "aUserDefinedMsgType"){
        if( msgMsg == "aUserDefinedMsg"){
            // do something with the data
        }
    }

}


default {
    state_entry() {
        llSetText("",<1,1,1>,1); // in case we displayed an error before
        // reset irc-handler as last part of startup
        llMessageLinked( LINK_THIS, LNK_MSG_RESET, "", "" );
    }
    link_message(integer sender_num, integer num, string msg, key id){
        if( num == LNK_MSG_RECV ){
            // incoming message intended for us, so send to handler
            handleMessage( msg, (string)id );
        }
    }
}