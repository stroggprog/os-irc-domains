# headcounter

This is a simple example of a head counter to see how many avatars and NPCs are in your regions.

This isn't a great example of good use of the IRCBridge, but it shows how simple it is to use.

## Requires
The following osSL functions are required:

  - osGetAgents (default permissions: ESTATE_MANAGER,ESTATE_OWNER)
  - osIsNpc (default permissions: always available)

## How to use
  1. Ensure the description for each of these prims (both the clients and the server) are unique.
  2. Place the edited "IRC-Datastore.lsl" script (from the repository root) in all prims that will be suing the script
  3. Place the "IRC-Client.lsl" script (from the repository root) in all prims that will be using the bridge.
  4. Place the "IRC-Avatar Counter Client.lsl" in a prim in each region you want to fetch a headcount for.
  5. Place the "IRC-Avatar Counter Server.lsl" in the 'server' prim.

Touch the server prim to activate the request. When the responses come back from each of the counter prims, the server prim will chat the response in an llOwnerSay message.

Note that if you want the server to display the counts for the region the server is in, you'll have to make a client prim for that region too.
