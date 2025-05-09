/*
Copyright (c) 2025 Zen Drako @ moss.mossgrid.uk (not an email address)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
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

integer lhandle = 0;
integer postcards = 0;

relay( string message, string who ){
    llMessageLinked( LINK_THIS, LNK_MSG_SEND, message, who );
}

handleMessage( string msg, string senderDetails ){
    // senderDetails = "from-address, from-region", use llCSV2List
    // msg = "POST::COUNT::MSG_DATA"
    // senderDetails = [from-region, from-address]
    list details = llParseStringKeepNulls( msg, ["::"], [] );
    if( llList2String( details, MSG_TYPE ) == "POST" ){
        if( llList2String( details, MSG_MSG ) == "COUNT" ){
            postcards = (integer) llList2String( details, MSG_DATA );
            setText();
        }
    }
}

integer random(){
    return 0x80000000 | (integer)llFrand(65536) | ((integer)llFrand(65536) << 16);
}

endListen(){
    if( lhandle != 0 ){
        llListenRemove( lhandle );
        lhandle = 0;
    }
    llSetTimerEvent(0.0);
}

integer startListen( key avatar ){
    endListen();
    integer chan = random();
    lhandle = llListen( chan, "", avatar, "" );
    llSetTimerEvent(300.0);
    return chan;
}

integer countNC(){
    return postcards;
}
setText(){
    llSetText("Touch to enter a message\n"+countNC()+" postcards delivered",<1,1,1>,1.0);
}

sendNotecard( string name, string data ){
    data = llEscapeURL("Grid: "+osGetGridNick()+"\n----\n"+data);
    relay( "POST::DELIVER::"+name+";;"+data, llList2CSV(["*","postal.main"]) );
}

default {
    state_entry() {
        setText();
        llMessageLinked( LINK_THIS, LNK_MSG_RESET, "", "" );
    }
    touch_start(integer num){
        key avatar = llDetectedKey(0);
        integer chan = startListen( avatar );
        llTextBox( avatar, " \n", chan );
    }
    listen(integer channel, string name, key id, string msg){
        endListen();
        sendNotecard( name, msg );
        llRegionSayTo( id, 0, "Thank you, postcard has been delivered" );
    }
    timer(){
        endListen();
    }
    on_rez( integer num ){
        llResetScript();
    }
    link_message(integer sender_num, integer num, string msg, key id){
        if( num == LNK_MSG_RECV ){
            // incoming message intended for us, so send to handler
            handleMessage( msg, (string)id );
        }
    }
}
