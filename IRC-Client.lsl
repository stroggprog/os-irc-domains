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

string password="myPassword";

integer __DEBUG__;
//integer __DEBUG__ = TRUE;

integer LNK_MSG_RECV = -4247894;
integer LNK_MSG_SEND = -4247895;
integer LNK_MSG_RESET = -4247896;
integer LNK_MSG_READY = -4247897;

integer IRC_FROM_ID     = 0;
integer IRC_FROM_REGION = 1;
integer IRC_TO_ID       = 2;
integer IRC_TO_REGION   = 3;
integer IRC_MSG_TYPE    = 4;
integer IRC_MSG_TYPE2   = 5;
integer IRC_MESSAGE     = 6;

integer relay_private_channel_out = -48484842;
integer relay_private_channel_in =  -48484843;
string from;

list from_list;
integer from_list_len;
list ldata;

// options are [ to_region, to_address ]
list defaultOptions = [ "*", "*" ];
integer MSG_OPTS_REGION     = 0;
integer MSG_OPTS_ADDRESS    = 1;

key listen_handle;
string my_region;
string myuuid;

debug( string text ){
    if( __DEBUG__ ){
        // we can do instant message instead, if owner is probably in another region
        // remember that instant messages incur a 2.0 second penalty
        //llInstantMessage( llGetOwner(),  text );
        llOwnerSay( text );
    }
}

list parseString( string data ){
    data = llReplaceSubString( data, ", ::", "::", 0);
    return llParseStringKeepNulls( data, ["::"], [] );
}

list breakAddress( string data ){
    return llParseStringKeepNulls( data, ["."], [] );
}

// options are [ to_region, to_address ]
// text is in form MSG_TYPE::data
//
relay( string text, list options ){
    if( options == [] ){
        options = defaultOptions;
    }
    string to_region = llList2String( options, MSG_OPTS_REGION );
    string to_addr   = llList2String( options, MSG_OPTS_ADDRESS );
    if( to_region != my_region ){
        llSay(relay_private_channel_out,llList2CSV([password,from,to_addr,"::"+to_region+"::"+text]) ); // IRC server
    }
    // note this string is in a different format from the one we send to the IRC server
    // we have to emulate what the IRCBridge sends
    string lmsg = from+"::"+my_region+"::"+to_addr+", ::"+to_region+"::"+text;
    llRegionSay( relay_private_channel_in, lmsg );
}

integer checkAddressIsUs( string who ){
    integer retval = FALSE;
    string s0;
    string s1;
    integer i = 0;
    integer l = from_list_len;
    list addr = breakAddress( who );
    integer p = llGetListLength( addr );
    
    if( p < l ){
        l = p;
    }
    else if( p > l ){
        // longer address than us = not us
        i = l+1;
    }
    while( i < l ){
        retval = FALSE; // always reset on a loop
        s0 = llList2String( addr, i );
        s1 = llList2String( from_list, i );
        if( s0 == "*" || s0 == s1 ){
            retval = TRUE;
        }
        if( !retval ){
            i = l;
        }
        i++;
    }
    return retval;
}

integer checkForMe( string region, string who ){
    integer retval = FALSE;
    if( region == "*" || region == my_region ){
        if( who == "*" || who == from ){
            retval = TRUE;
        }
        else {
            retval = checkAddressIsUs( who );
        }
    }
    debug("4me: "+retval+", "+region+", "+who+", "+from);
    return retval;
}

startup(){
    from = llGetObjectDesc();
    from_list = breakAddress( from );
    from_list_len = llGetListLength( from_list );
    my_region = llGetRegionName();
    myuuid = (string)llGetLinkKey(LINK_ROOT);
    
    relay_private_channel_in = (integer) llLinksetDataRead("relay_private_channel_in");
    relay_private_channel_out = (integer) llLinksetDataRead("relay_private_channel_out"); 
    password = llLinksetDataRead("irc-bridge-password");
    
    listen_handle = llListen(relay_private_channel_in, "",NULL_KEY , "");
    llSay(0, "Ready");
    relay( "PING::PING;;"+myuuid, [] ); // check we have a unique address (region name doesn't qualify)
}

default {
    state_entry() {
        startup();
        llMessageLinked( LINK_THIS, LNK_MSG_READY, "", "" );
    }
    on_rez( integer startup ){
        llResetScript();
    }
    listen(integer channel, string name, key id, string msg){
        list data = parseString( llStringTrim(msg, STRING_TRIM) );
        // is this for me?
        debug(msg);
        if( checkForMe( llList2String( data, IRC_TO_REGION ), llList2String( data, IRC_TO_ID ) ) ){
            debug("for me");
            // do something
            string dmsg = llList2String( data, IRC_MESSAGE );
            list lmsg = llParseStringKeepNulls( dmsg, [";;"], [] );
            string qmsg = llList2String( lmsg, 0 );
            if( qmsg == "PING" ){
                if( llList2String( data, IRC_FROM_ID ) == from ){
                    // get the UUID so we target the specific prim and don't disable
                    // similar named prims (shouldn't happen, but it might)
                    string uuid = llList2String( lmsg, 1 );
                    relay( "PONG::PONG;;"+uuid, 
                            [llList2String( data, IRC_FROM_REGION ), llList2String( data, IRC_FROM_ID )] );
                }
            }
            else if( qmsg == "PONG" ){
                string uuid = llList2String( lmsg, 1 );
                if( uuid == myuuid ){
                    llSetText("Disabled, clashing peers",<1.0, 0.685, 0.0>,1.0);
                    llSay(0,"Disabled, clashing peers");
                    llSetScriptState( llGetScriptName(), FALSE );
                }
            }
            else {
                string sender = llList2String( data, IRC_FROM_REGION )+", "+llList2String( data, IRC_FROM_ID );
                string xmsg = llList2String( data, IRC_MSG_TYPE )+"::"+
                                llList2String( data, IRC_MSG_TYPE2 )+
                                "::"+dmsg;
                llMessageLinked( LINK_THIS, LNK_MSG_RECV, xmsg, sender );
            }
        }
        /*
        // uncomment to prove ignoring when testing
        else {
            debug("not doing anything");
            
        }
        */
    }
    link_message( integer sender, integer num, string msg, key id ){
        if( num == LNK_MSG_SEND ){
            list who = llCSV2List( id );
            // do something
            relay( msg, who );
        }
        else if( num == LNK_MSG_RESET ){
            llResetScript();
        }
    }
}
