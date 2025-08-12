# Quick-Start GodotSteam Template Project

This project contains a minimal setup of interchangable SteamMultiplayerPeer and ENetMultiplayerPeer to quickly get started with multiplayer development.

# Steam + LAN

The template allows to play scenes locally with multiple instances as well as playing with a friend (or co-developer) via Steam online, without any additional changes necessary to the netcode (IF Godots High-Level-Multiplayer-API is used).

The project uses the GDExtensions "GodotSteam" and "SteamMultiplayerPeer".

# Important Info

The NetworkManager class has 2 variables that need to be adjusted to your specifications.

The 'steam_app_id' variable should be ID of your Steam-App, in case you have one. Otherwise leave this at 480 (which will appear as "Space Wars", somewhat of a proxy-game for testing Steam features.

The 'steam_lobby_filter' is a String that is used to identify lobbies of your specific game (otherwise, the lobby list will show ALL test lobbies from other projects that currently use the 480 test ID).
Set this to something unique, like YOUR_GAME_NAME_XYZ or something.

<img width="1014" height="631" alt="Screenshot_4" src="https://github.com/user-attachments/assets/dd4fd7c6-a120-4e15-86c0-91699bbc26f2" />
