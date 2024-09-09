#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Elizabeth and Eldrish"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "testPlugin"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "This is just a test lol we'll see if the programming works",
	version = PLUGIN_VERSION,
	url = ""
};
	
	int playerScores[MAXPLAYERS + 1];
	
	Handle syncedTimer;
	
	Handle playerNamesArray;
	
//When the plugin is loaded in
public void OnPluginStart()
{
	//To simulate the Ray Gun
	ServerCommand("sv_cheats 1");
	ServerCommand("sv_flare_gun_explode_damage 750");
	ServerCommand("sv_cheats 0");
	
	RegConsoleCmd("gunStore", displayGunStore);
	RegConsoleCmd("ammoStore", displayAmmoStore);
	
	RegConsoleCmd("setPoints", setClientPoints, "");
	
	
	ServerCommand("bind \"o\" \"say /gunStore\"");
	ServerCommand("bind \"p\" \"say /ammoStore\"");
	
	
	HookEvent("npc_killed", Event_NpcKilled, EventHookMode_Post);
	HookEvent("zombie_head_split", Event_zombieHeadSplit, EventHookMode_Post);
	HookEvent("player_join", Event_playerJoined, EventHookMode_Post);
	HookEvent("nmrih_reset_map", Event_mapReset, EventHookMode_Post);
	HookEvent("nmrih_round_begin", Event_roundBegin, EventHookMode_Post);
}

//Zombie stuffs
public void OnEntityCreated(int entity, const char[] classname)
{
	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage); //when entity is created, hook damage
}

//Degub - Set's players points to 1000
public void setPlayerPoints(int client) 
{
	int player = GetClientUserId(client);
	playerScores[player] = 1000;
}

//Method for returning a player's points
public int returnPlayerPoints(int client)
{
	int x = GetClientUserId(client);
	return playerScores[x];
}

//Method to add points to a player
public void addPointsToPlayer(int client, int addPoints)
{
	//score = playerScores[1]
	int x = GetClientUserId(client);
	int score = playerScores[x];
	int newScore = score + addPoints;
	playerScores[x] = newScore;
}

//Method to subtract points from a player
public void subtractPointsFromPlayer(int client, int subPoints)
{
	//score = playerScores[1]
	int x = GetClientUserId(client);
	int score = playerScores[x];
	int newScore = score - subPoints;
	playerScores[x] = newScore;
}

//Method to set all player points to 500
public void resetAllPoints()
{
	for (int i = 0; i < MAXPLAYERS+1; i++)
	{
		playerScores[i] = 500;
	}	
}

//Method executed when the command /setPoints is called, set's players points to 1000
public Action setClientPoints(int client, int args)
{
	//Get client
	int player = GetClientUserId(client);
	
	//buff for args
	char argPoints[15];
	GetCmdArg(1, argPoints, 8);
	
	//Convert to int
	int newArgPoints = StringToInt(argPoints);
	
	//Setting player score to desired points
	playerScores[player] = newArgPoints;
}

//Action - Gives points to player when the zombie takes damage
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
	//PrintToChatAll("attacker was client %d which did %f damage", attacker, damage);
	
	//get the victim classname to safely check if it's a zombie
	char victimClass[32];
	GetEntityClassname(victim, victimClass, 32); //maxlength = 32
	
	//victim is a fake client(zombie), attacker is client
	if(isZombieClass(victimClass) && attacker < MAXPLAYERS + 1)
	{
		addPointsToPlayer(attacker, 10);
	}
	
	return Plugin_Continue;
}

//Action Method - excuted to bind keys to commands and some other things
public void Event_playerJoined(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("bind \"o\" \"say /gunStore\"");
	ServerCommand("bind \"p\" \"say /ammoStore\"");
}

//Executes when the round officially begins
public void Event_roundBegin(Event event, const char[] name, bool dontBroadcast)
{
	syncedTimer = CreateHudSynchronizer();
	CreateTimer(1.0, pointsHUD, _, TIMER_REPEAT);
	
	//Maybe this should fix the binding to everyone(?)
	ServerCommand("bind \"o\" \"say /gunStore\"");
	ServerCommand("bind \"p\" \"say /ammoStore\"");
	
}

public Action pointsHUD(Handle timer)
{
	
	playerNamesArray = CreateArray(MAXPLAYERS);
	
	char dataForHud[1024];
	char playerData[1024];
	char name[1024];
			
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			
			GetClientName(i, name, sizeof(name));
			Format(playerData, 1024, "%s : %i\n", name, returnPlayerPoints(i));
			PushArrayString(playerNamesArray, playerData);
		}
	}

	for (int j = 0; j < GetArraySize(playerNamesArray); j++)
	{
		char x[1024];
		GetArrayString(playerNamesArray, j, x, 1024);
		StrCat(dataForHud, 1024, x);
	}
	
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			switch(i)
			{
				//White
				case 1:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 210, 210, 211, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);
				}
				//Blue
				case 2:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 120, 204, 234, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);
				}
				//Yellow
				case 3:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 225, 180, 62, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);
				}
				//Green
				case 4:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 121, 225, 127, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);
				}
				//White
				case 5:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 210, 210, 211, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);

				}
				//Blue
				case 6:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 120, 204, 234, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);
				}
				//Yellow
				case 7:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 225, 180, 62, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);
				}
				//Green
				case 8:
				{
					SetHudTextParams(0.010, 0.45, 0.5, 121, 225, 127, 255, 0, 6.0, 0.1, 0.2);
					ShowSyncHudText(i, syncedTimer, dataForHud);
				}
			}
		}
	}
}

//resets all players points to 0 when the map is changed
public void Event_mapReset(Event event, const char[] name, bool dontBroadcast)
{
	resetAllPoints(); 
}

//Method to add 100 points when a zombie is killed
public void Event_NpcKilled(Event event, const char[] name, bool dontBroadcast)
{
	int userID = event.GetInt("killeridx");
	addPointsToPlayer(userID, 100);
}

//Method to add 150 points when zombie head is split (both head split(50) and NPCkilled(100) events are called, = 150 points)
public void Event_zombieHeadSplit(Event event, const char[] name, bool dontBroadcast)
{
	//returns 1
	int userID = event.GetInt("player_id");
	addPointsToPlayer(userID, 50);
}

//Method for Mysterybox
static Action giveMysteryWeapon(Handle timer, int client)
{
	//array that holds strings of random weapons (15 weapons, max string length is 32)
	char mysteryBox[][] =  {"fa_sw686", 			//revolver
							"fa_mkiii",				//ruger
							"fa_mp5a3",				//mp5
							"fa_m16a4",				//m16 acog
							"fa_500a",				//Mossberg
							"bow_deerhunter",		//bow
							"fa_jae700",			//Remington JAE-700
							"tool_flare_gun",		//flare gun
							"exp_tnt",				//TNT
							"fa_cz858",				//CZ858
							"fa_sks",				//SKS
							"fa_superx3",			//super x3
							"fa_1911",				//Colt
							"fa_fnfal",				//FAL
							"fa_winchester1892"}; 	//winchester
	
	PrintToChatAll("Random weapon generated");
	//EmitSoundToClient(client, "Mystery_Box_Sound.mp3");
	GivePlayerItem(client, mysteryBox[GetRandomInt(0, 14)]);	//getRandomInt is inclusive on both min and max
}

public int GetWeaponClipSize(int entity)
{
	int ClipSize = 0;
	char classname[21];
	
	if(!IsValidEdict(entity))
		ClipSize = -1;
	else	
		GetEdictClassname(entity, classname, sizeof(classname));
	
	if(StrEqual(classname, "tool_flare_gun")
		|| StrEqual(classname, "tool_barricade")
		|| StrContains(classname, "exp_") == 0
		|| StrEqual(classname, "bow_deerhunter")
		|| StrEqual(classname, "exp_grenade")
		|| StrEqual(classname, "exp_molotov")
		|| StrEqual(classname, "exp_tnt"))
		ClipSize = 1;
	else if(StrEqual(classname, "fa_sv10"))
		ClipSize = 2;
	else if(StrEqual(classname, "fa_sako85")
		|| StrEqual(classname, "fa_superx3")
		|| StrEqual(classname, "fa_sako85")
		|| StrEqual(classname, "fa_sako85_ironsights")
		|| StrEqual(classname, "fa_500a"))
		ClipSize = 5;
	else if(StrEqual(classname, "fa_sw686"))
		ClipSize = 6;
	else if(StrEqual(classname, "fa_1911"))
		ClipSize = 7;
	else if(StrEqual(classname, "fa_870"))
		ClipSize = 8;
	else if(StrEqual(classname, "fa_1022")
		|| StrEqual(classname, "fa_mkiii")
		|| StrEqual(classname, "fa_sks")
		|| StrEqual(classname, "fa_sks_nobayo")
		|| StrEqual(classname, "fa_jae700"))
		ClipSize = 10;
	else if(StrEqual(classname, "fa_m92fs")
		|| StrEqual(classname, "fa_winchester1892"))
		ClipSize = 15;
	else if(StrEqual(classname, "fa_glock17"))
		ClipSize = 17;
	else if(StrEqual(classname, "fa_fnfal"))
		ClipSize = 20;
	else if(StrEqual(classname, "1022_25mag"))
		ClipSize = 25;
	else if(StrEqual( classname, "fa_cz858")
		|| StrEqual(classname, "fa_m16a4")
		|| StrEqual(classname, "fa_mp5a3")
		|| StrEqual(classname, "fa_mac10")
		|| StrEqual(classname, "fa_m16a4_carryhandle"))
		ClipSize = 30;
	else if(StrEqual(classname, "me_chainsaw"))
		ClipSize = 100;
	
	return ClipSize;
}

//Method that displays the gun store
public Action displayGunStore(int client, int args)
{
	Menu gunMenu = new Menu(gunStoreHandler);
	gunMenu.SetTitle("Elizabeths's Gun Store");
	
	//All Items available in the gun store
	AddMenuItem(gunMenu, "COLT", "Colt 1911 (500)");
	AddMenuItem(gunMenu, "GLOCK", "Glock 17 (200)");
	AddMenuItem(gunMenu, "BERETTA", "Beretta M92FS (200)");
	AddMenuItem(gunMenu, "RUGAR_25", "Ruger 10/22 (25Mag)(500)");
	AddMenuItem(gunMenu, "SAKO", "Sako 85 (500)");
	AddMenuItem(gunMenu, "WINCHESTER_X3", "Winchester SX3 (1750)");
	AddMenuItem(gunMenu, "SV", "SV-10 (1200)");
	AddMenuItem(gunMenu, "WINCHESTER_1892", "Winchester 1892 (1500)");
	AddMenuItem(gunMenu, "MAC", "Mac-10 (1200)");
	AddMenuItem(gunMenu, "FN", "FN-FAL (2000)");
	AddMenuItem(gunMenu, "Mystery", "MysteryBox (950)");
	
	gunMenu.ExitButton = true;
	gunMenu.Display(client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

//Method that checks what to do on the gun menu (option-select)
public int gunStoreHandler(Menu gunMenu, MenuAction action, int param1, int param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char item[64];
		GetMenuItem(gunMenu, param2, item, sizeof(item));

			if(StrEqual(item, "COLT")) 
			{
				if(returnPlayerPoints(param1) < 500)
				{
					PrintToChat(param1, "You don't have 500 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 500);
					GivePlayerItem(param1, "fa_1911");
				}
			}
			
			else if(StrEqual(item, "GLOCK"))
			{
				if(returnPlayerPoints(param1) < 200)
				{
					PrintToChat(param1, "You don't have 200 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 200);
					GivePlayerItem(param1, "fa_glock17");
				}
			}
			
			else if(StrEqual(item, "BERETTA"))
			{
				if(returnPlayerPoints(param1) < 200)
				{
					PrintToChat(param1, "You don't have 200 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 200);
					GivePlayerItem(param1, "fa_m92fs");
				}
			}
			
			else if(StrEqual(item, "RUGAR"))
			{
				if(returnPlayerPoints(param1) < 500)
				{
					PrintToChat(param1, "You don't have 500 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 500);
					GivePlayerItem(param1, "fa_m92fs");
				}
			}
			
			else if(StrEqual(item, "SAKO"))
			{
				if(returnPlayerPoints(param1) < 500)
				{
					PrintToChat(param1, "You don't have 500 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 500);
					GivePlayerItem(param1, "fa_sako85");
				}
			}
			
			else if(StrEqual(item, "WINCHESTER_X3"))
			{
				if(returnPlayerPoints(param1) < 1750)
				{
					PrintToChat(param1, "You don't have 1750 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 1750);
					GivePlayerItem(param1, "fa_sako85");
				}
			}
			
			else if(StrEqual(item, "SV"))
			{
				if(returnPlayerPoints(param1) < 1200)
				{
					PrintToChat(param1, "You don't have 1200 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 1200);
					GivePlayerItem(param1, "fa_sv10");
				}
				
			}
			
			else if(StrEqual(item, "WINCHESTER_1892"))
			{
				if(returnPlayerPoints(param1) < 1500)
				{
					PrintToChat(param1, "You don't have 1500 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 1500);
					GivePlayerItem(param1, "fa_winchester1892");
				}
			}
			
			else if(StrEqual(item, "MAC"))
			{
				if(returnPlayerPoints(param1) < 1200)
				{
					PrintToChat(param1, "You don't have 1200 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 1200);
					GivePlayerItem(param1, "fa_mac10");
				}
			}
			
			else if(StrEqual(item, "FN"))
			{
				if(returnPlayerPoints(param1) < 2000)
				{
					PrintToChat(param1, "You don't have 2000 points!");
				}
				else
				{
					subtractPointsFromPlayer(param1, 2000);
					GivePlayerItem(param1, "fa_fnfal");
				}
				
			}
			else if(StrEqual(item, "Mystery"))
			{
				if(returnPlayerPoints(param1) < 950)
				{
					PrintToChat(param1, "You don't have 950 points!");
				}
				else
				{
					PrecacheSound("*/Mystery_Box_Sound.mp3");
					int clientArr[1];
					clientArr[0] = param1;
					EmitSound(clientArr, 1, "*/Mystery_Box_Sound.mp3", param1);
					subtractPointsFromPlayer(param1, 950);
					CreateTimer(4.7, giveMysteryWeapon, param1);
				}
				
			}
	}
	
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		//delete gunMenu;
	}
}

 //Method that displays the ammo store
public Action displayAmmoStore(int client, int args)
{
	Menu ammoMenu = new Menu(ammoStoreHandler);
	
	ammoMenu.SetTitle("Eldrish's Ammo Store");
	AddMenuItem(ammoMenu, "ammo1", "Super Sick Ammo'");
	//AddMenuItem(menu, "loadAmmoShop", "Eldrish's Ammo");
	ammoMenu.ExitButton = true;
	ammoMenu.Display(client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

//Handles all ammo store items
public int ammoStoreHandler(Menu menu, MenuAction action, int param1, int param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char item[64];
		GetMenuItem(menu, param2, item, sizeof(item));

			if(StrEqual(item, "ammo1"))
			{
				PrintToChatAll("You bought Eldrish's Ammo!, he'll appreciate that a lot :)");
				int Weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");

				int iPAmmoOffs = FindDataMapOffs(param1, "m_iAmmo");
				if(GetEntData(param1, (iPAmmoOffs + GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType") * 4), 4) < GetWeaponClipSize(Weapon) * 5)
				{
					SetEntData(param1, (iPAmmoOffs + GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType") * 4), GetWeaponClipSize(Weapon) * 5, _, true );
				}
	}
//End of function
}
	
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
 
//checks if a given class is one of the 4 nmrih zombie entity classes
static void isZombieClass(char className[32])
{
	return 	StrEqual(className, "npc_nmrih_shamblerzombie") || 
			StrEqual(className, "npc_nmrih_turnedzombie") ||
			StrEqual(className, "npc_nmrih_kidzombie") ||
			StrEqual(className, "npc_nmrih_runnerzombie");
}
