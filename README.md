# os-irc-domains

This script allows prims in OpenSimulator (not SecondLife) to communicate via the IRCBridgeModule, where each prim using the module has a guaranteed unique identity (stored in the description of the object). Such objects can then communicate with each other, and can target individual prims or groups of prims, and can set a filter based on region. The prims are in a peer-to-peer network, so any prim can act as a server at any time.

Since the IRCBridgeModule is grid agnostic, objects in one grid can communicate with objects in another grid. It is necessary to configure `opensim.ini` to use the IRCBridgeModule, therefore you must control each region in which you wish to use it.

All messages are sent are first-class messages, so do not require a response. Any response is also a first-class message. When a message is delivered, the sending object's details are available to the recipient: the full address (see [Domains](#domains) below) of the object and the region it is in. This is sufficient to target any response back to the sender (the region data is superfluous in this case as the address itself is unique).

A message may instruct an object to perform some action, return information or trigger it to send further messages. Whatever action the object takes in response to a message is entirely up to you.

When sending a message, only two messages are sent: one to the IRCBridgeModule, which forwards it to the IRC chatroom where other regions can receive the message, and one to the region the object resides in (because an IRC enabled region cannot hear itself), ensuring any objects in the same region that ought to receive the message do.

All IRC-enabled objects in all IRC-enabled regions will receive every message, but the addressing system is a highly efficient and performant way to filter out messages not intended for an object. This allows objects to only respond to messages intended for them. The core code is a black-box script that requires no editing, and the user script that allows you to define actions and reactions - to send outbound messages and handle inbound messages - is extremely simple.

## Requires
No OSSL functions are required.

## IRCBridgeModule
You can learn how to setup the IRCBridgeModule at this webpage on the [OpenSimulator.org](http://opensimulator.org/wiki/IRCBridgeModule#Object_chat_relay_mode) website. Note that you should configure for "Object Chat Relay Mode". For performance reasons, it is best to setup an IRC server on the same local network as the simulators. IRC servers use very little resources and are available for most operating systems.

There are some specifics to the `[IRC]` section in `opensim.ini`:

```lsl
msgformat = "PRIVMSG {0} : {1}::{2}::{3}"
```

If this is set to anything else, the scripts in this repository will fail to work.

## Domains

Each prim has a unique identity held in the object description. It may be as simple as ''AnObjectName'', but it can also have a more complex name similar to an internet domain name. With an internet domain name, the top-level domain is furthest right, e.g. the last domain in the name: ''google.com'' is an example, where ''com'' is a top level domain, and ''google'' is a subdomain of ''com''.

In the system used in this code, the top-level domain is on the left: ''com.google''. This makes the code simpler and more efficient, and names easier to understand and edit. Imagine a vending system:

```
    # vending groups
    #
    vend.furniture.tables
    vend.furniture.chairs
    vend.furniture.sofas

    # example of individual vendors
    #
    vend.furniture.tables.dining
    vend.furniture.tables.office
    vend.furniture.chairs.01
    vend.furniture.chairs.02
```

You can send a message to an individual vendor by using its full address: `vend.furniture.chairs.01`

You can send a message to a group using the group name and the wildcard:

```
    # example of group addresses
    vend.furniture.tables.*         // go to all members in the tables group
    vend.furniture.*                // go to all members in the furniture group

    # vend.furniture.* messages will go to:
    vend.furniture.tables.*
    vend.furniture.chairs.*
    vend.furniture.sofas.*

    vend.* # messages sent here will go to all prims whose address begins with "vend."

```

Being able to achieve this with a single message makes it much easier and much more powerful than using http. HTTP requires an external server so objects can determine the URL of the object they want to talk to, and there is a throttle on the rate of http requests an owner can make. An object's URL changes whenever the object is re-rezzed, the scripts are reset or the region is restarted. With the IRCBridgeModule and this script, all you need to know is the domain name of the object, which only changes if you edit it.

IRC communications are also incredibly fast - much faster than HTTP. All that is required is an IRC channel to use exclusively for yourself. The easiest way to do this is to run your own IRC server and block access to it from outside your network by closing the ports at the router (they shouldn't be open anyway) and maybe setting up a firewall with exceptions for your region servers.

As a peer-to-peer system, when an object starts up (script is reset) it must ensure it has a unique name. It does this by announcing itself to the network, which is achieved with a `PING` message. If another object has the same address, it returns a `PONG`. When the prim that is starting up receives a `PONG` from another prim with the same address (sender address details are sent with every message), it displays some hovertext to announce why it has shut down, then stops the script. After correcting the issue, the script must be manually restarted.

The `IRC-Client` script sends any messages you feed it to the IRCBridgeModule, and also sends it to IRC-enabled prims in the same region as itself (otherwise they wouldn't hear it - IRC doesn't send messages to the sender). When a prim receives a message it determines whether it is in the intended recipient group, and if not it ignores the message. If it was intended to receive it, it passes the message back to your own script to handle as you see fit.

## Scripts
This section describes the three main scripts provided in this repository. There is an assumption that before you use any of these scripts, your region has been correctly configured to use an actively running IRC server and chat room, and the region has been (re-)started.

### IRC-Datastore.lsl
This script should be edited and dropped into the object before any other scripts. It stores some pertinent settings in the object's data store then removes itself from the object's inventory.

The settings are the channels the IRCBridgeModule uses to listen on for outbound messages and send on for inbound messages, and the password used to access the IRCBridgeModule (not the password to access the chat room you created).

```lsl
list secrets = [
                "relay_private_channel_out", -48484842,
                "relay_private_channel_in" , -48484843,
                "irc-bridge-password"      , "myPassword" // the password to the IRC Bridge, not the chat room
                ];

```

### IRC-Client.lsl
Prior to putting this script in the object, ensure the object's description contains a unique address as described [above](#domains). Once the description is correctly set, and after dropping in the [IRC-Datastore](#irc-datastore.lsl) script, simply drop this script in and it will add the object to the current IRC network. This script should not be edited.

### IRC-User-template.lsl
Your object should by now be able to send and receive messages on the IRC network. However, you have no way to handle any incoming messages that your object should be interested in, nor can you send messages to other objects. This is all handled in `IRC-User-template.lsl`, which you can rename to anything you want - the convention is to call it `IRC-User`.

Within this function is a function with the following profile:

```lsl
handleMessage( string msg, string senderDetails );
```

When a message arrives it is passed to this function. Only messages intended for this object will be passed to this function.

The `msg` is broken down into several components:

```lsl
string msgType;
string msgMsg;
list data;
```

Each of these can have an arbitrary value that you define. The `data` portion is a list of zero or more data components that you sent to act as parameters. The list stores these as strings, but you can cast the list elements to anything you want when you extract them. Note that for vector and rotation values, you should take care when casting:

```lsl
vector v0 = llList2Vector( data, 0 );          // wrong
vector v1 = (vector) llList2String( data, 0 ); // correct
```

The reason for this is because the `llList2Vector` function expects a vector in that list element, and in fact there is a string.

The `msgType` and `msgMsg` values can be used to identify what your code should do. In most cases you only need to set one of these and the other can be ignored (but should still be sent with a dummy value). For example, your code might look like this:

```lsl
string param == llList2String( data, 0 );

if( msgType == "LIGHT" ){
    turnLightOnOff( (integer) param );
}
else if( msgType == "GOTO" ){
    if( msgMsg == "POS" ){
        llSetPos( (vector) param );
    }
    else if( msgMsg == "HEIGHT" ){
        vector pos = llGetPos();
        pos.z = (float) param;
        llSetPos( pos );
    }
}
```

As you can see, this shows usage for just one of the message values and also for using both.

To send messages to another object or group of objects, you use the relay function which has the following profile:

```lsl
relay( string message, string who )
```

The message is constructed in the following manner:
```lsl
list params = [param1m param2, param3];                   // add as many as you like, an empty list is ok.
string data = llDumpList2String( params, dataSeparator );
string message = "MSG_TYPE::MSG_MSG::"+data;              // replace "MSG_TYPE" and "MSG_MSG" values as you require
```

The value `dataSeparator` is defined at the top of the file and can be changed to almost anything you want. You cannot set it to anything that might appear in your data, nor can you set it to `::`. The default is `;;`.

The `who` parameter to the relay is also a stringified list:

```lsl
string region = "*";  // target all regions
string address = "*"; // target all addresses
string who = llList2CSV( [ region, address ] );
```

You can restrict which objects react to the message by specifying their address or part of it. Note that if the last part of the address you specify is not an asterisk, then only an object with that exact address will respond. If there is an asterisk, then any objects with a matching address will reply, where the asterisk acts as a wildcard meaning 'anything'.

```
// acceptable addressing modes
//
vend.furniture.tables.office.*
vend.*.tables.*.luxury
vend.*.tables.*
vend.*
```

If you want to send to all objects, then you can pass a blank string instead of `"*, *"` each time:

```lsl
relay( "LIGHT::DUMMY::1", "" );
```

Alternately, if this object is always sending to the same group, you can add a default at the top of the file:

```lsl
string sendTo = "*, lamps.*";

// then when you need to send a message:
relay( yourMessage, sendTo );
```
