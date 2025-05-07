integer LNK_MSG_RECV  = -4247894;
integer LNK_MSG_SEND  = -4247895;
integer LNK_MSG_RESET = -4247896;
integer LNK_MSG_READY = -4247897;

integer IRC_FROM_ID     = 0;
integer IRC_FROM_REGION = 1;
integer IRC_TO_ID       = 2;
integer IRC_TO_REGION   = 3;
integer IRC_MSG_TYPE    = 4;
integer IRC_MESSAGE     = 5;

// options are [ to_region, to_address ]
list defaultOptions = [ "*", "*" ];
integer MSG_OPTS_REGION     = 0;
integer MSG_OPTS_ADDRESS    = 1;

// msg sections
integer MSG_TYPE = 0;
integer MSG_MSG = 1;

// local messages (local to object group)
string REQ_REGION_INFO = "REQ_REGION_INFO";
string ANS_REGION_INFO = "ANS_REGION_INFO";

string msgDiv = ";;"; // anything except | or || or ::

relay( string message, list who ){
    if( who == [] ){
        who = defaultOptions;
    }
    llMessageLinked( LINK_THIS, LNK_MSG_SEND, message, llList2CSV(who) );
}

handleMessage( string msg, list senderDetails ){
    // msg = "MSG_TYPE::MSG_MSG;;data"
    // senderDetails = [from-region, from-address]
    list details = llParseStringKeepNulls( msg, ["::"], [] );
    string msgType = llList2String( details, MSG_TYPE );
    string msg = llList2String( details, MSG_MSG );

    // split data from msg code
    list data = llParseStringKeepNulls( msg, msgDiv, "" );
    string xmsg = llList2String( data, 0 );
    string grid = "Moss";

    if( llGetListLength( data ) > 1 ){
        data = llList2List( data, 1, -1);
    }
    
    if( xmsg == ANS_REGION_INFO ){
        string msgData = llList2String( data, 0 );
        grid = llList2String( data, 0 );

        integer avatars = llList2Integer( data, 1 );
        integer npcs = llList2Integer( data, 2 );
        
        string region = llList2String( senderDetails, MSG_OPTS_REGION );
        
        llOwnerSay("Region: "+Grid+"/"+region+": Agents: "+avatars+", NPCs: "+npcs);
    }
}

default {
    state_entry() {
        llSetText( "", ZERO_VECTOR, 1.0 );
        // reset irc-handler as last part of startup
        llMessageLinked( LINK_THIS, LNK_MSG_RESET, "", "" );
    }
    touch_start( integer num ){
        if( llDetectedKey(0) == llGetOwner() ){
            relay( REQ_REGION_INFO+"::", [] );
        }
    }
    link_message(integer sender_num, integer num, string msg, key id){
        if( num == LNK_MSG_RECV ){
            // incoming message intended for us, so send to handler
            list sender = llCSV2List( id );
            handleMessage( msg, sender );
        }
    }
}
