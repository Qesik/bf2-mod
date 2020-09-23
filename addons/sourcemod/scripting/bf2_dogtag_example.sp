#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <battlefield2>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "BattleField Dog Tag Shop",
	author = "-_- (Karol Skupień)",
	description = "BattleField Dog Tag Shop",
	version = "0.1",
	url = "https://forum.cs-classic.pl/"
};

char gWeaponShop[ 9 ][ 2 ][ ] = {
	{ "m4a1", "ak47" },
	{ "m4a1_silencer", "galilar" }, 
	{ "famas", "sg556" },
	{ "aug", "mac10" },
	{ "usp_silencer", "sawedoff" },
	{ "fiveseven", "glock" },
	{ "cz75a", "tec9" },
	{ "mp9", "" },
	{ "mag7", "" }
};
int gCostShop[ 9 ] [ 2 ] = {
	{ 31, 27 },
	{ 29, 18 },
	{ 20, 32 },
	{ 33, 10 },
	{ 2, 11 },
	{ 5, 2 },
	{ 5, 5 },
	{ 12, 0 },
	{ 13, 0 }
};

bool gCanBuy = false;
Handle gTimerBuy;

public void OnPluginStart(/*void*/) {
	// command
	RegConsoleCmd("sm_sklep", cmd_Shop, "[BF2] SKLEP");
	// event
	HookEvent("round_start", evRoundStart, EventHookMode_PostNoCopy);
}

public void OnMapEnd(/*void*/) {
	gTimerBuy = null;
}

public Action cmd_Shop(int iClient, int iArgs) {
	if ( !( 1 <= iClient <= MaxClients ) || !IsClientInGame(iClient) )
		return Plugin_Continue;

	if ( GetClientTeam(iClient) <= 1 || !IsPlayerAlive(iClient) || GameRules_GetProp("m_bWarmupPeriod") == 1 )
		return Plugin_Continue;

	if ( !gCanBuy ) {
		PrintToChat(iClient, "Your buy period has expired");
		return Plugin_Continue;
	}

	char sMenu[64];
	Menu mMenu = new Menu(MenuShop_H);

	FormatEx(sMenu, sizeof(sMenu), "[BF2] GUNS MENU\n%d Dog Tag", bf2_get_dogtag(iClient));
	mMenu.SetTitle(sMenu);
	/*							EASY OPTION										*/
	int iTeam = GetClientTeam(iClient) == CS_TEAM_T ? 0 : 1;
	for(int i = 0; i < (iTeam == 1 ? 7 : 9); i++)
	{
		FormatEx(sMenu, sizeof(sMenu), "%s [%d Dog Tag]", gWeaponShop[i][iTeam], gCostShop[i][iTeam]);
		mMenu.AddItem("", sMenu);
	}
	mMenu.Display(iClient, 45);

	return Plugin_Continue;
}
public int MenuShop_H(Menu mMenu, MenuAction mAction, int iClient, int iParam) {
	if ( mAction == MenuAction_End ) {
		delete mMenu;
	} else if ( mAction == MenuAction_Select ) {
		if ( !IsPlayerAlive(iClient) )
			return 0;

		if ( !gCanBuy ) {
			PrintToChat(iClient, "Your buy period has expired");
			return 0;
		}

		char sWeaponName[64];
		int iDogTag = bf2_get_dogtag(iClient);
		/*							EASY OPTION										*/
		int iTeam = GetClientTeam(iClient) == CS_TEAM_T ? 0 : 1;
		if ( iDogTag < gCostShop[iParam][iTeam] ) {
			PrintToChat(iClient, "You don't have enought Dog Tag!");
			return 0;
		}

		bf2_set_dogtag(iClient, iDogTag - gCostShop[iParam][iTeam]);
		FormatEx(sWeaponName, sizeof(sWeaponName), "weapon_%s", gWeaponShop[iParam][iTeam]);
		GivePlayerItem(iClient, sWeaponName);
	}
	return 0;
}

public Action evRoundStart(Event eEvent, const char[] sName, bool bDontBroadcast) {
	if ( GameRules_GetProp("m_bWarmupPeriod") == 1 )
		return;

	gCanBuy = true;

	delete gTimerBuy;
	gTimerBuy = CreateTimer(20.0, Timer_BlockBuy, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_BlockBuy(Handle hTimer) {
	gCanBuy = false;
	gTimerBuy = null;
	return Plugin_Stop;
}