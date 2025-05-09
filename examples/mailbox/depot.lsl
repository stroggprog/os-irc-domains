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

integer linkRod = 11;
integer linkFlag = 12;

relay( string message, string who ){
    llMessageLinked( LINK_THIS, LNK_MSG_SEND, message, who );
}

handleMessage( string msg, string senderDetails ){
    // senderDetails = [from-region, from-address]
    list details = llParseStringKeepNulls( msg, ["::"], [] );

    if( llList2String( details, MSG_TYPE ) == "POST" ){
        if( llList2String( details, MSG_MSG ) == "DELIVER" ){
            string msgData = llList2String( details, MSG_DATA );
            list data = llParseStringKeepNulls( msgData, [";;"], [] );
            list contents = ["Posted: "+breakTime(),
                                "Region: "+llList2String( llCSV2List(senderDetails), 0 ),
                                llUnescapeURL( llList2String( data, 1 ) )];
            osMakeNotecard( llList2String( data, 0 ), llDumpList2String(contents, "\n") );
            updatePostcardCount();
        }
    }
}

updatePostcardCount(){
    relay( "POST::COUNT::"+llGetInventoryNumber( INVENTORY_NOTECARD ), "*, postal.*" );
    setFlag();
}

string breakTime(){
    list time = llParseStringKeepNulls( osUnixTimeToTimestamp( llGetUnixTime() ), ["T","."], [] );
    string t = llList2String( time, 0 )+" "+llList2String( time, 1 );
    return t;
}

setText( string text ){
    llSetLinkPrimitiveParams( linkFlag, [PRIM_TEXT, text, <1,0.685,0>, 1.0] );
}

setFlag(){
    setText("");
    integer mode = 0;
    integer count = llGetInventoryNumber( INVENTORY_NOTECARD );
    if( count ){
        mode = 1;
        setText( (string) count + " postcards" );
    }
    // set a child link invisible (no postcards) or visible (postcards available)
    llSetLinkPrimitiveParamsFast( LINK_ALL_CHILDREN, [PRIM_COLOR, ALL_SIDES, <1,1,1>, (float) mode] );
}

default {
    state_entry() {
        llSetText("",<1,1,1>,1); // in case we displayed an error before
        // reset irc-handler as last part of startup
        llMessageLinked( LINK_THIS, LNK_MSG_RESET, "", "" );
        updatePostcardCount();
    }
    touch_start( integer num ){
        if( llDetectedKey(0) == llGetOwner() ){
            list cards = osGetInventoryNames( INVENTORY_NOTECARD );
            if( cards == [] ){
                llOwnerSay("Nothing to deliver!");
            }
            else {
                llGiveInventoryList( llGetOwner(), "Postcards", cards );
                integer i = llGetListLength( cards );
                while( i > 0 ){
                    string name = llGetInventoryName( INVENTORY_NOTECARD, i-1 );
                    llRemoveInventory( name );
                    i--;
                }
            }
            updatePostcardCount();
        }
    }
    link_message(integer sender_num, integer num, string msg, key id){
        if( num == LNK_MSG_RECV ){
            // incoming message intended for us, so send to handler
            handleMessage( msg, (string)id );
        }
    }
}
