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

// local messages (local to object group)
string REQ_REGION_INFO = "REQ_REGION_INFO";
string ANS_REGION_INFO = "ANS_REGION_INFO";

relay( string message, string who ){
    llMessageLinked( LINK_THIS, LNK_MSG_SEND, message, who );
}

handleMessage( string msg, string senderDetails ){
    // senderDetails = [from-region, from-address]
    list details = llParseStringKeepNulls( msg, ["::"], [] );
    string msgType = llList2String( details, MSG_MSG );
    string msgData = llList2String( details, MSG_DATA );
        
    if( msgType == REQ_REGION_INFO ){
        //llSay(0,"handling msg: "+msgType+", "+msgData);
        // no data with this one
        integer i = 0;
        integer avatars = 0;
        integer npcs = 0;
        list agents = llGetAgentList(AGENT_LIST_REGION, []);
        integer l = llGetListLength( agents );
        key who;
        while( i < l ){
            who = llList2Key( agents, i );
            if( osIsNpc( who ) ){
                npcs++;
            }
            else {
                avatars++;
            }
            i++;
        }
        msg = "MSG::"+ANS_REGION_INFO+";;Agents: "+avatars+", NPCs: "+npcs;
        msg = "MSG::"+ANS_REGION_INFO+";;"+osGetGridNick()+";;"+avatars+";;"+npcs;
        //llSay(0, "sending: "+msg );
        llMessageLinked( LINK_THIS, LNK_MSG_SEND, msg, senderDetails );
    }
}

default {
    state_entry() {
        llSetText("",<1,1,1>,1);
        // reset irc-handler as last part of startup
        llMessageLinked( LINK_THIS, LNK_MSG_RESET, "", "" );
    }
    link_message(integer sender_num, integer num, string msg, key id){
        if( num == LNK_MSG_RECV ){
            // incoming message intended for us, so send to handler
            //llOwnerSay( msg+"@"+id);
            handleMessage( msg, (string)id );
        }
    }
}
