# headcounter

This is a simple example of a message mailer. It is a more useful example of using the IRC system because it allows avatars to leave messages on any of your regions and have them delivered to a central location. The postbox prims can be in a different grid from the depot prim, but all regions containing a postbox or depot prim must be IRC enabled and configured by you.

Avatars can leave a message at a mailbox by touching it and entering their message into a dialogue box. The message is then sent via IRC to the 'depot', which records it in a notecard named after the person who sent the message. Subsequent messages by the same avatar are numbered e.g. "Zen Drako", "Zen Drako 1", "Zen Drako 2" etc.

Notecards contain header information: The date/time the notecard was created, and the region and Grid it was posted from.

When a postcard is delivered, the depot prim will send out a message to all the mailbox prims telling them how many messages are waiting to be read. In response to this message, the mailboxes display in hover text the number of messages. This way, all mailboxes show the same number no matter where messages were sent from.

When the owner touches the depot prim, the notecards are delivered in a folder (and removed from the depot prim's inventory). The postboxes are updated with the new count (of course that will be zero).

If the depot prim has a child prim, it will be made visible when there are pending messages, and invisible when there are none. This allows you to have a visual clue that messages are pending.

## Requires
The following osSL functions are required:

  - osMakeNotecard ${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER
  - osUnixTimeToTimestamp (always allowed)
  - osGetInventoryNames (always allowed)

## How to use
  1. Ensure the description for each of these prims (both the clients and the server) are unique.
  2. Place the edited "IRC-Datastore.lsl" script (from the repository root) in all prims that will be using the script
  3. Place the "IRC-Client.lsl" script (from the repository root) in all prims that will be using the bridge.
  4. Place the "postbox.lsl" in a mailbox prim
  5. Place the "depot.lsl" in the prim that collects the mail.

Touch a mailbox prim to deliver a message to the depot.
Touch the depot prim to receive pending messages in a folder.
