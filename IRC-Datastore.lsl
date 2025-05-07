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

// you can add to secrets to inject additional keys into your prim
// change the values to suit your configuration
//
// IRC-Client will load these values. They must be set or you'll get script errors
list secrets = [
                "relay_private_channel_out", -48484842,
                "relay_private_channel_in" , -48484843,
                "irc-bridge-password"      , "myPassword" // the password to the IRC Bridge, not the chat room
                ];

default {
    state_entry() {
        integer l = llGetListLength( secrets );
        integer i = 0;
        while( i < l ){
            string name = llList2String( secrets, i );
            string value = llList2String( secrets, i+1 );
            llLinksetDataWrite( name, value );
            i = i+2;
        }
        llSay( 0, "Data injected: "+(integer)(l/2));
        llRemoveInventory( llGetScriptName() );
    }
}
