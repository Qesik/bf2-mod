/**
 * =============================================================================
 * SourceMod 
 * XYZ ZYX
 *
 * SourceMod (C)
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#include <bf2_engine>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "BattleField 2",
	author = "-_- (Karol Skupień)",
	description = "BattleField 2",
	version = "1.15",
	url = "https://github.com/Qesik/bf2-mod"
};

enum struct ClientInfo 
{
	bool LoadData;

	int Rank;
	int Stats[14];

	int mBadges[MAX_BADGES];
	int mMedal[3];

	int sFrags;
	int sShoot;
	int sHit;
	int sKillsRound[7];
	int sKillsHSRound[6];
	int MenuSelect;

	void ResetVars(/*void*/)
	{
		this.LoadData = false;
		
		this.Rank = 0;
		for(int i = 0; i < 12; i++)	this.Stats[i] = 0;

		for(int i = 0; i < MAX_BADGES; i++)	this.mBadges[i] = 0;
		for(int i = 0; i < 3; i++) this.mMedal[i] = 0;

		this.sFrags = 0;
		this.sShoot = 0;
		this.sHit = 0;
		for(int i = 0; i < 7; i++) this.sKillsRound[i] = 0;
		for(int i = 0; i < 6; i++) this.sKillsHSRound[i] = 0;
		this.MenuSelect = 0;
	}
}
ClientInfo gClientInfo[MAXPLAYERS];

enum struct ServerData
{
	Database DBK;
	int TopFrags[3];

	ConVar cVarMinPlayers;
	ConVar cVarXpMultiplier;
	ConVar cVarScreenTime;
	ConVar cVarOvLanguage;

	void ResetVars(/*void*/)
	{
		this.TopFrags[0] = 0;
		this.TopFrags[1] = 0;
		this.TopFrags[2] = 0;
	}
}
ServerData gServerData;

/*
	* * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * * 
	* * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * *
*/
char gRankName[ MAX_RANKS ][ ] = {
	"Szeregowy", "Starszy Szeregowy", "Kapral", "Starszy Kapral", "Plutonowy",
	"Sierżant", "Starszy Sierżant", "Młodyszy Chorąży", "Chorąży", "Starszy Chorąży",
	"Podporucznik", "Porucznik", "Kapitan", "Major",
	"Podpułkownik", "Pułkownik", "Generał Brygady"
};
/*char gRankName[ MAX_RANKS ][ ] = {
	"Private", "Private First Class", "Lance Corporal", "Corporal", "Sergeant",
	"Staff Sergeant", "Gunnery Sergeant", "Master Sergeant", "Master Gunnery Sergeant", "2nd Lieutenant",
	"1st Lieutenant", "Captain", "Major", "Lieutenant Colonel",
	"Colonel", "Brigadier General", "Lieutenant General"
};*/

int gRankXP[ MAX_RANKS ] = {
	0, 150, 500, 800, 2500,
	5000, 8000, 20000, 50000, 60000,
	75000, 90000, 115000, 125000, 150000,
	180000, 200000
};


char gBadgeName[ MAX_BADGES ][ 5 ][ ] = {
	{ "", "Name_Badge1_Basic", "Name_Badge1_Veteran", "Name_Badge1_Expert", "Name_Badge1_Profesional" },
	{ "", "Name_Badge2_Basic", "Name_Badge2_Veteran", "Name_Badge2_Expert", "Name_Badge2_Profesional" },
	{ "", "Name_Badge3_Basic", "Name_Badge3_Veteran", "Name_Badge3_Expert", "Name_Badge3_Profesional" },
	{ "", "Name_Badge4_Basic", "Name_Badge4_Veteran", "Name_Badge4_Expert", "Name_Badge4_Profesional" },
	{ "", "Name_Badge5_Basic", "Name_Badge5_Veteran", "Name_Badge5_Expert", "Name_Badge5_Profesional" },
	{ "", "Name_Badge6_Basic", "Name_Badge6_Veteran", "Name_Badge6_Expert", "Name_Badge6_Profesional" },
	{ "", "Name_Badge7_Basic", "Name_Badge7_Veteran", "Name_Badge7_Expert", "Name_Badge7_Profesional" },
	{ "", "Name_Badge8_Basic", "Name_Badge8_Veteran", "Name_Badge8_Expert", "Name_Badge8_Profesional" }
};

char gBadgeInfo[ MAX_BADGES ][ ] = {
	"Info_Badge1",
	"Info_Badge2",
	"Info_Badge3",
	"Info_Badge4",
	"Info_Badge5",
	"Info_Badge6",
	"Info_Badge7",
	"Info_Badge8"
};

char gBadgeInfoRequirements[ MAX_BADGES ][ 5 ][ ] = {
	{ "", "Req_Badge1_Basic", "Req_Badge1_Veteran", "Req_Badge1_Expert", "Req_Badge1_Profesional" },
	{ "", "Req_Badge2_Basic", "Req_Badge2_Veteran", "Req_Badge2_Expert", "Req_Badge2_Profesional" },
	{ "", "Req_Badge3_Basic", "Req_Badge3_Veteran", "Req_Badge3_Expert", "Req_Badge3_Profesional" },
	{ "", "Req_Badge4_Basic", "Req_Badge4_Veteran", "Req_Badge4_Expert", "Req_Badge4_Profesional" },
	{ "", "Req_Badge5_Basic", "Req_Badge5_Veteran", "Req_Badge5_Expert", "Req_Badge5_Profesional" },
	{ "", "Req_Badge6_Basic", "Req_Badge6_Veteran", "Req_Badge6_Expert", "Req_Badge6_Profesional" },
	{ "", "Req_Badge7_Basic", "Req_Badge7_Veteran", "Req_Badge7_Expert", "Req_Badge7_Profesional" },
	{ "", "Req_Badge8_Basic", "Req_Badge8_Veteran", "Req_Badge8_Expert", "Req_Badge8_Profesional" }
};

char gBadgeInfoAwards[ MAX_BADGES ][ 5 ][ ] = {
	{ "", "Award_Badge1_Basic", "Award_Badge1_Veteran", "Award_Badge1_Expert", "Award_Badge1_Profesional" },
	{ "", "Award_Badge2_Basic", "Award_Badge2_Veteran", "Award_Badge2_Expert", "Award_Badge2_Profesional" },
	{ "", "Award_Badge3_Basic", "Award_Badge3_Veteran", "Award_Badge3_Expert", "Award_Badge3_Profesional" },
	{ "", "Award_Badge4_Basic", "Award_Badge4_Veteran", "Award_Badge4_Expert", "Award_Badge4_Profesional" },
	{ "", "Award_Badge5_Basic", "Award_Badge5_Veteran", "Award_Badge5_Expert", "Award_Badge5_Profesional" },
	{ "", "Award_Badge6_Basic", "Award_Badge6_Veteran", "Award_Badge6_Expert", "Award_Badge6_Profesional" },
	{ "", "Award_Badge7_Basic", "Award_Badge7_Veteran", "Award_Badge7_Expert", "Award_Badge7_Profesional" },
	{ "", "Award_Badge8_Basic", "Award_Badge8_Veteran", "Award_Badge8_Expert", "Award_Badge8_Profesional" }
};


float gKnifeDmgHP[ 5 ] = {
	0.0, 0.2, 0.4, 0.6, 0.8
};
int gChanceFreezeValue[ 5 ] = {
	0, 20, 25, 33, 55
};
int gHealthValue[ 5 ] = {
	100, 110, 120, 130, 140
};
int gBonusDMG[ 5 ] = {
	0, 2, 4, 6, 8
};
float gMultiplierDMGHE[ 5 ] = {
	0.0, 0.15, 0.3, 0.45, 0.6
};
int gInvisAlphaValue[ 5 ] = {
	255, 200, 180, 160, 140
};
float gMultiplierSpeed[ 5 ] = {
	0.0, 0.1, 0.2, 0.3, 0.4
};

// =============================================================//
// 						OnPluginStart							//
// =============================================================//
public void OnPluginStart(/*void*/)
{
	LoadTranslations("bf2mod.phrases");

	OnRegCommand(/*void*/);
	OnEvent(/*void*/);
	OnCvar(/*void*/);
}
// =============================================================//
// 							OnMapStart							//
// =============================================================//
public void OnMapStart(/*void*/)
{
	ServerCommand("sv_disable_immunity_alpha 1");
	gServerData.ResetVars(/*void*/);

	onMapDownload(/*void*/);

	sql_CreateDataBase(/*void*/);
}
// =============================================================//
// 						OnClientDisconnect						//
// =============================================================//
public void OnClientDisconnect(int client)
{
	sql_SaveDataClient(client);
	gClientInfo[client].ResetVars(/*void*/);
}
// =============================================================//
// 						OnClientPutInServer						//
// =============================================================//
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage,			sdk_OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlivePost,	sdk_OnTakeDamageAlivePost);
	SDKHook(client, SDKHook_WeaponSwitchPost,		sdk_WeaponSwitch);

	gClientInfo[client].ResetVars(/*void*/);
	sql_LoadDataClient(client);
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
#define DATABASE_CONFIG_NAME "bf2mod"
#define FILELOG_ERROR "addons/sourcemod/logs/bf2.log"

void sql_CreateDataBase(/*void*/)
{
	if ( gServerData.DBK == null && SQL_CheckConfig(DATABASE_CONFIG_NAME) )
	{
		char error[256];
		gServerData.DBK = SQL_Connect(DATABASE_CONFIG_NAME, true, error, sizeof(error));
		if ( gServerData.DBK == null ) {
			LogToFile(FILELOG_ERROR, "[ERROR SQL] Couldnt connect : %s", error);
			return;
		}

		gServerData.DBK.SetCharset("utf8");
		SQL_LockDatabase(gServerData.DBK);

		if (
			!SQL_FastQuery(gServerData.DBK, "CREATE TABLE IF NOT EXISTS `bf2_players` \
			( \
			`authID` INT NOT NULL default 0, \
			`steamID` VARCHAR(32) NOT NULL default '', \
			`player_name` VARCHAR(64) NOT NULL default '', \
			`lastlog` INT NOT NULL default 0, \
			`badge1` INT NOT NULL default 0, \
			`badge2` INT NOT NULL default 0, \
			`badge3` INT NOT NULL default 0, \
			`badge4` INT NOT NULL default 0, \
			`badge5` INT NOT NULL default 0, \
			`badge6` INT NOT NULL default 0, \
			`badge7` INT NOT NULL default 0, \
			`badge8` INT NOT NULL default 0, \
			`kills` INT NOT NULL default 0, \
			`kills_knife` INT NOT NULL default 0, \
			`kills_pistol` INT NOT NULL default 0, \
			`kills_m249` INT NOT NULL default 0, \
			`kills_sniper` INT NOT NULL default 0, \
			`kills_rifle` INT NOT NULL default 0, \
			`kills_shotgun` INT NOT NULL default 0, \
			`kills_smg` INT NOT NULL default 0, \
			`kills_grenade` INT NOT NULL default 0, \
			`plant_bomb` INT NOT NULL default 0, \
			`explode_bomb` INT NOT NULL default 0, \
			`defuse_bomb` INT NOT NULL default 0, \
			`medal_gold` INT NOT NULL default 0, \
			`medal_silver` INT NOT NULL default 0, \
			`medal_bronze` INT NOT NULL default 0, \
			PRIMARY KEY (authID), \
			UNIQUE (steamID) \
			) ENGINE = InnoDB;")
		)
		{
			SQL_GetError(gServerData.DBK, error, sizeof(error));
			LogToFile(FILELOG_ERROR, "[ERROR SQL] Couldnt create table %s", error);
		}

		SQL_UnlockDatabase(gServerData.DBK);
	}
}

// =============================================================//
// 						sql_LoadDataClient						//
//																//
// =============================================================//
public void sql_LoadDataClient(int client)
{
	if ( !IsClientConnected(client) || gClientInfo[client].LoadData )
		return;

	if ( gServerData.DBK != null )
	{
		int authID = GetSteamAccountID(client);

		if ( authID == 0 )
			return;

		char fQuery[512];
		FormatEx(fQuery, sizeof(fQuery), "SELECT \
		`badge1`, `badge2`, `badge3`, `badge4`, `badge5`, `badge6`, `badge7`, `badge8`, \
		`kills`, `kills_knife`, `kills_pistol`, `kills_m249`, `kills_sniper`, `kills_rifle`, `kills_shotgun`, `kills_smg`, `kills_grenade`, \
		`plant_bomb`, `explode_bomb`, `defuse_bomb`, \
		`medal_gold`, `medal_silver`, `medal_bronze` \
		FROM `bf2_players` WHERE `authID`='%d';",
		authID);
		gServerData.DBK.Query(sql_LoadDataClientH, fQuery, GetClientUserId(client), DBPrio_High);
	}
}
public void sql_LoadDataClientH(Database db, DBResultSet results, const char[] sError, int clientID)
{
	int client = GetClientOfUserId(clientID);

	if ( !IsValidClient(client) || gClientInfo[client].LoadData )
		return;

	if ( db == null ) {
		LogToFile(FILELOG_ERROR, "[ERROR SQL] sql_LoadDataClientH : %s", sError);
		return;
	}

	if ( results == null ) {
		LogToFile(FILELOG_ERROR, "[ERROR SQL] Results sql_LoadDataClientH : %s", sError);
		return;
	}

	if ( results.RowCount && results.FetchRow() )
	{
		gClientInfo[client].LoadData = true;

		int b = 0;
		for(int i = 0; i < MAX_BADGES; i++)	gClientInfo[client].mBadges[i] = results.FetchInt(b++);
		for(int i = 0; i < 12; i++)	gClientInfo[client].Stats[i] = results.FetchInt(b++);
		for(int i = 0; i < 3; i++)	gClientInfo[client].mMedal[i] = results.FetchInt(b++);

		BF_CheckRank(client, true);
		
		return;
	}

	gClientInfo[client].LoadData = true;

	char pName[MAX_NICKNAME], pNameEscape[MAX_NICKNAME*2+1], steamID[32];

	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	GetClientName(client, pName, sizeof(pName));
	SQL_EscapeString(gServerData.DBK, pName, pNameEscape, sizeof(pNameEscape));

	char fQuery[1024];
	FormatEx(fQuery, sizeof(fQuery), "INSERT INTO `bf2_players` \
	(`authID`, `steamID`, `player_name`, `lastlog`, \
	`badge1`, `badge2`, `badge3`, `badge4`, `badge5`, `badge6`, `badge7`, `badge8`, \
	`kills`, `kills_knife`, `kills_pistol`, `kills_m249`, `kills_sniper`, `kills_rifle`, `kills_shotgun`, `kills_smg`, `kills_grenade`, \
	`plant_bomb`, `explode_bomb`, `defuse_bomb`, \
	`medal_gold`, `medal_silver`, `medal_bronze`) \
	VALUES \
	('%d', '%s', '%s', '%d', \
	'0', '0', '0', '0', '0', '0', '0', '0', \
	'0', '0', '0', '0', '0', '0', '0', '0', '0', \
	'0', '0', '0', \
	'0', '0', '0');",
	GetSteamAccountID(client), steamID, pNameEscape, GetTime());
	
	if ( !SQL_FastQuery(gServerData.DBK, fQuery, sizeof(fQuery)) ) {
		BF2_PrintToChat(client, "tb error load data");
		gClientInfo[client].LoadData = false;

		char Error[256];
		SQL_GetError(gServerData.DBK, Error, sizeof(Error));
		LogToFile(FILELOG_ERROR, "%s", fQuery);
		LogToFile(FILELOG_ERROR, "[ERROR SQL] Create sql_LoadDataClientH: %s", Error);
	}
}

// =============================================================//
// 						sql_SaveDataClient						//
//																//
// =============================================================//
public void sql_SaveDataClient(int client)
{
	if ( IsFakeClient(client) || !gClientInfo[client].LoadData )
		return;

	char pName[MAX_NICKNAME], pNameEscape[MAX_NICKNAME*2+1];
	GetClientName(client, pName, sizeof(pName));
	SQL_EscapeString(gServerData.DBK, pName, pNameEscape, sizeof(pNameEscape));

	char fQuery[1024];
	FormatEx(fQuery, sizeof(fQuery), "UPDATE `bf2_players` SET \
	`player_name`='%s', `lastlog`='%d', \
	`badge1`='%d', `badge2`='%d', `badge3`='%d', `badge4`='%d', `badge5`='%d', `badge6`='%d', `badge7`='%d', `badge8`='%d', \
	`kills`='%d', `kills_knife`='%d', `kills_pistol`='%d', `kills_m249`='%d', `kills_sniper`='%d', `kills_rifle`='%d', \
	`kills_shotgun`='%d', `kills_smg`='%d', `kills_grenade`='%d', \
	`plant_bomb`='%d', `explode_bomb`='%d', `defuse_bomb`='%d', \
	`medal_gold`='%d', `medal_silver`='%d', `medal_bronze`='%d' \
	WHERE `authID`='%d';", pNameEscape, GetTime(),
	gClientInfo[client].mBadges[BADGE_KNIFE], gClientInfo[client].mBadges[BADGE_PISTOL], gClientInfo[client].mBadges[BADGE_ASSAULT],
	gClientInfo[client].mBadges[BADGE_SNIPER], gClientInfo[client].mBadges[BADGE_SUPPORT], gClientInfo[client].mBadges[BADGE_EXPLOSIVES],
	gClientInfo[client].mBadges[BADGE_SHOTGUN], gClientInfo[client].mBadges[BADGE_SMG],
	gClientInfo[client].Stats[KILL_ALL], gClientInfo[client].Stats[KILL_KNIFE], gClientInfo[client].Stats[KILL_PISTOL],
	gClientInfo[client].Stats[KILL_M249], gClientInfo[client].Stats[KILL_SNIPER], gClientInfo[client].Stats[KILL_RIFLE], 
	gClientInfo[client].Stats[KILL_SHOTGUN], gClientInfo[client].Stats[KILL_SMG], gClientInfo[client].Stats[KILL_GRENADE], 
	gClientInfo[client].Stats[PLANT_BOMB], gClientInfo[client].Stats[EXPLODE_BOMB], gClientInfo[client].Stats[DEFUSE_BOMB], 
	gClientInfo[client].mMedal[MEDAL_GOLD], gClientInfo[client].mMedal[MEDAL_SILVER], gClientInfo[client].mMedal[MEDAL_BRONZE], 
	GetSteamAccountID(client));

	if ( !SQL_FastQuery(gServerData.DBK, fQuery, sizeof(fQuery)) ) {
		char Error[256];
		SQL_GetError(gServerData.DBK, Error, sizeof(Error));
		LogToFile(FILELOG_ERROR, "%s", fQuery);
		LogToFile(FILELOG_ERROR, "[ERROR SQL] Save sql_SaveDataClient: %s", Error);
	}
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
void OnEvent(/*void*/)
{
	HookEvent("player_spawn",		ev_PlayerSpawn,		EventHookMode_Post);
	HookEvent("player_death",		ev_PlayerDeath,		EventHookMode_Post);
	HookEvent("bomb_planted",		ev_BombPlanted,		EventHookMode_Post);
	HookEvent("bomb_exploded",		ev_BombExploded,	EventHookMode_Post);
	HookEvent("bomb_defused",		ev_BombDefused,		EventHookMode_Post);
	HookEvent("cs_win_panel_match",	ev_CsWinPanelMatch,	EventHookMode_PostNoCopy);
	HookEvent("weapon_fire",		ev_WeaponFire,		EventHookMode_Post);
	HookEvent("player_hurt",		ev_PlayerHurt,		EventHookMode_Post);
}

// =============================================================//
// 						ev_PlayerSpawn							//
// 																//
// =============================================================//
public Action ev_PlayerSpawn(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if ( !IsValidClient(client) )
		return Plugin_Continue;

	for(int i = 0; i < 7; i++) gClientInfo[client].sKillsRound[i] = 0;
	for(int i = 0; i < 6; i++) gClientInfo[client].sKillsHSRound[i] = 0;

	if ( gClientInfo[client].mBadges[BADGE_ASSAULT] )
		SetEntData(client, FindDataMapInfo(client, "m_iHealth"), gHealthValue[gClientInfo[client].mBadges[BADGE_ASSAULT]]);

	if ( gClientInfo[client].mBadges[BADGE_SMG] )
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", (1.0 + gMultiplierSpeed[gClientInfo[client].mBadges[BADGE_SMG]]));

	if ( gClientInfo[client].mBadges[BADGE_SNIPER] && GetRandomInt(1, (5 - gClientInfo[client].mBadges[BADGE_SNIPER])) == 1 )
		GivePlayerItem(client, "weapon_awp");

	if ( gClientInfo[client].mBadges[BADGE_EXPLOSIVES] && GetRandomInt(1, (5 - gClientInfo[client].mBadges[BADGE_EXPLOSIVES])) == 1 )
		GivePlayerItem(client, "weapon_hegrenade");

	BF2_PrintToChat(client, "tb info rank", gRankName[gClientInfo[client].Rank], gClientInfo[client].Stats[KILL_ALL]);

	return Plugin_Continue;
}
// =============================================================//
// 						ev_PlayerDeath							//
// 																//
// =============================================================//
public Action ev_PlayerDeath(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if ( GetClientCount(true) < gServerData.cVarMinPlayers.IntValue || GameRules_GetProp("m_bWarmupPeriod") == 1 )
		return Plugin_Continue;

	int killer = GetClientOfUserId(hEvent.GetInt("attacker"));
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	bool headshot = hEvent.GetBool("headshot");

	if ( !IsValidClient(killer) || !IsValidClient(victim) || GetClientTeam(victim) == GetClientTeam(killer) || !gClientInfo[killer].LoadData )
		return Plugin_Continue;

	gClientInfo[killer].sFrags ++;
	
	gClientInfo[killer].Stats[KILL_ALL] ++;
	BF_CheckRank(killer, false);
	
	char WeaponName[64];
	hEvent.GetString("weapon", WeaponName, sizeof(WeaponName));
	CSWeaponID weaponID = CS_AliasToWeaponID(WeaponName);

	switch(weaponID)
	{
		case CSWeapon_GLOCK, CSWeapon_ELITE, CSWeapon_FIVESEVEN, CSWeapon_DEAGLE, CSWeapon_TEC9, CSWeapon_HKP2000, CSWeapon_P250, 
		CSWeapon_USP_SILENCER, CSWeapon_CZ75A, CSWeapon_REVOLVER :
		{
			gClientInfo[killer].Stats[KILL_PISTOL] ++;
			gClientInfo[killer].sKillsRound[BADGE_PISTOL] ++;
			if ( headshot )
				gClientInfo[killer].sKillsHSRound[BADGE_PISTOL - 1] ++;
		}
		case CSWeapon_HEGRENADE :
		{
			gClientInfo[killer].Stats[KILL_GRENADE] ++;
		}
		case CSWeapon_XM1014, CSWeapon_MAG7, CSWeapon_SAWEDOFF, CSWeapon_NOVA :
		{
			gClientInfo[killer].Stats[KILL_SHOTGUN] ++;
			gClientInfo[killer].sKillsRound[BADGE_SHOTGUN - 1] ++;
			if ( headshot )
				gClientInfo[killer].sKillsHSRound[BADGE_SHOTGUN - 2] ++;

		}
		case CSWeapon_MAC10, CSWeapon_UMP45, CSWeapon_MP5NAVY, CSWeapon_P90, CSWeapon_BIZON, CSWeapon_MP7, CSWeapon_MP9 :
		{
			gClientInfo[killer].Stats[KILL_SMG] ++;
			gClientInfo[killer].sKillsRound[BADGE_SMG - 1] ++;
			if ( headshot )
				gClientInfo[killer].sKillsHSRound[BADGE_SMG - 2] ++;
		}
		case CSWeapon_AUG, CSWeapon_FAMAS, CSWeapon_M4A1, CSWeapon_AK47, CSWeapon_GALILAR, CSWeapon_SG556, CSWeapon_M4A1_SILENCER :
		{
			gClientInfo[killer].Stats[KILL_RIFLE] ++;
			gClientInfo[killer].sKillsRound[BADGE_ASSAULT] ++;
			if ( headshot )
				gClientInfo[killer].sKillsHSRound[BADGE_ASSAULT - 1] ++;
		}
		case CSWeapon_AWP, CSWeapon_G3SG1, CSWeapon_SCAR20, CSWeapon_SSG08 :
		{
			gClientInfo[killer].Stats[KILL_SNIPER] ++;
			gClientInfo[killer].sKillsRound[BADGE_SNIPER] ++;
			if ( headshot )
				gClientInfo[killer].sKillsHSRound[BADGE_SNIPER - 1] ++;
		}
		case CSWeapon_M249 ://, CSWeapon_NEGEV :
		{
			gClientInfo[killer].Stats[KILL_M249] ++;
			gClientInfo[killer].sKillsRound[BADGE_SUPPORT] ++;
			if ( headshot )
				gClientInfo[killer].sKillsHSRound[BADGE_SUPPORT - 1] ++;
		}
		case CSWeapon_KNIFE, CSWeapon_KNIFE_GG, CSWeapon_KNIFE_T, CSWeapon_KNIFE_FLIP, CSWeapon_KNIFE_GUT, CSWeapon_KNIFE_KARAMBIT, 
		CSWeapon_KNIFE_M9_BAYONET, CSWeapon_KNIFE_TATICAL, CSWeapon_KNIFE_FALCHION, CSWeapon_KNIFE_SURVIVAL_BOWIE, CSWeapon_KNIFE_BUTTERFLY,
		CSWeapon_KNIFE_PUSH, CSWeapon_KNIFE_CORD, CSWeapon_KNIFE_CANIS, CSWeapon_KNIFE_URSUS, CSWeapon_KNIFE_GYPSY_JACKKNIFE, CSWeapon_KNIFE_OUTDOOR,
		CSWeapon_KNIFE_STILETTO, CSWeapon_KNIFE_WIDOWMAKER, CSWeapon_KNIFE_SKELETON :
		{
			gClientInfo[killer].Stats[KILL_KNIFE] ++;
			gClientInfo[killer].sKillsRound[BADGE_KNIFE] ++;
		}
	}

	RequestFrame(Check_Badges, killer);

	return Plugin_Continue;
}
// =============================================================//
// 						ev_BombPlanted							//
// 																//
// =============================================================//
public Action ev_BombPlanted(Event hEvent, const char[] eName, bool dontBroadcast)
{
	gClientInfo[GetClientOfUserId(hEvent.GetInt("userid"))].Stats[PLANT_BOMB] ++;
}
// =============================================================//
// 						ev_BombExploded							//
// 																//
// =============================================================//
public Action ev_BombExploded(Event hEvent, const char[] eName, bool dontBroadcast)
{
	gClientInfo[GetClientOfUserId(hEvent.GetInt("userid"))].Stats[EXPLODE_BOMB] ++;
}
// =============================================================//
// 						ev_BombDefused							//
// 																//
// =============================================================//
public Action ev_BombDefused(Event hEvent, const char[] eName, bool dontBroadcast)
{
	gClientInfo[GetClientOfUserId(hEvent.GetInt("userid"))].Stats[DEFUSE_BOMB] ++;
}
// =============================================================//
// 						ev_CsWinPanelMatch						//
// 																//
// =============================================================//
public Action ev_CsWinPanelMatch(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if ( GetClientCount(true) < 3 )
		return Plugin_Continue;

	SortByFrags();
	if ( IsValidClient(gServerData.TopFrags[0]) )
	{
		gClientInfo[gServerData.TopFrags[0]].mMedal[MEDAL_GOLD] ++;
		BF2_TranslationPrintToChatAll("tb top1 map", gServerData.TopFrags[0], gClientInfo[gServerData.TopFrags[0]].sFrags);
	}
	
	if ( IsValidClient(gServerData.TopFrags[1]) ) 
	{
		gClientInfo[gServerData.TopFrags[1]].mMedal[MEDAL_SILVER] ++;
		BF2_TranslationPrintToChatAll("tb top2 map", gServerData.TopFrags[1], gClientInfo[gServerData.TopFrags[1]].sFrags);
	}

	if ( IsValidClient(gServerData.TopFrags[2]) )
	{
		gClientInfo[gServerData.TopFrags[2]].mMedal[MEDAL_BRONZE] ++;
		BF2_TranslationPrintToChatAll("tb top3 map", gServerData.TopFrags[2], gClientInfo[gServerData.TopFrags[2]].sFrags);
	}

	return Plugin_Continue;
}
// =============================================================//
// 							ev_WeaponFire						//
// 																//
// =============================================================//
public Action ev_WeaponFire(Event hEvent, const char[] eName, bool dontBroadcast)
{
	gClientInfo[GetClientOfUserId(hEvent.GetInt("userid"))].sShoot ++;
}
// =============================================================//
// 							ev_PlayerHurt						//
// 																//
// =============================================================//
public Action ev_PlayerHurt(Event hEvent, const char[] eName, bool dontBroadcast)
{
	gClientInfo[GetClientOfUserId(hEvent.GetInt("attacker"))].sHit ++;
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
public Action sdk_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, 
	float damageForce[3], float damagePosition[3])
{
	if ( !IsPlayerAlive(victim) || !IsValidClient(attacker) )
		return Plugin_Continue;

	float new_damage = damage;

	if ( damagetype & DMG_BLAST && gClientInfo[attacker].mBadges[BADGE_EXPLOSIVES] > LEVEL_NONE )
		new_damage += damage * gMultiplierDMGHE[gClientInfo[attacker].mBadges[BADGE_EXPLOSIVES]];
	else if ( weapon != -1 && gClientInfo[attacker].mBadges[BADGE_SUPPORT] > LEVEL_NONE ) {
		CSWeaponID wID = CS_ItemDefIndexToID(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));

		if ( wID == CSWeapon_M249 )
			new_damage += gBonusDMG[gClientInfo[attacker].mBadges[BADGE_SUPPORT]];
	}

	if ( new_damage != damage ) {
		damage = new_damage;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void sdk_OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, 
	const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if ( !IsPlayerAlive(victim) || !IsValidClient(attacker) || weapon == -1 )
		return;

	if ( GetPlayerWeaponSlot(attacker, CS_SLOT_KNIFE) == weapon && gClientInfo[attacker].mBadges[BADGE_KNIFE] ) {
		int new_hp = GetClientHealth(attacker) + RoundFloat(damage * gKnifeDmgHP[gClientInfo[attacker].mBadges[BADGE_KNIFE]]);
		int max_hp = gHealthValue[gClientInfo[attacker].mBadges[BADGE_ASSAULT]];
		SetEntData(attacker, FindDataMapInfo(attacker, "m_iHealth"), (new_hp < max_hp) ? new_hp : max_hp);
	}

	if ( 
		GetPlayerWeaponSlot(attacker, CS_SLOT_SECONDARY) == weapon && 
		gClientInfo[attacker].mBadges[BADGE_PISTOL] && GetRandomInt(1, 100) <= gChanceFreezeValue[gClientInfo[attacker].mBadges[BADGE_PISTOL]] 
	) {
		SetEntityMoveType(victim, MOVETYPE_NONE);
		SetEntityRenderColor(victim, 0, 128, 255, 192);
		BF2_PrintToChat(attacker, "tb freeze client", victim);

		CreateTimer(1.0, Timer_RemoveFrozen, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void sdk_WeaponSwitch(int client, int weaponEnt)
{
	if ( !IsValidEntity(weaponEnt) )
		return;
	
	if ( GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == weaponEnt && gClientInfo[client].mBadges[BADGE_SHOTGUN] ) {
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, gInvisAlphaValue[gClientInfo[client].mBadges[BADGE_SHOTGUN]]);
	}
	else {
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}

}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
void OnCvar(/*void*/)
{
	gServerData.cVarOvLanguage = CreateConVar("bf2_overlays_language", "en", "Set overlays language: 'en' or 'pl'");
	gServerData.cVarMinPlayers = CreateConVar("bf2_min_players", "2", "Minimum players");
	gServerData.cVarXpMultiplier = CreateConVar("bf2_xp_multiplier", "0.1", "Point multiplier needed to reach each level (float)");
	gServerData.cVarScreenTime = CreateConVar("bf2_icon_time", "2.0", "Amount of time to display the rank icons (float)");

	AutoExecConfig(true, "BF2_Mod");
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
void OnRegCommand(/*void*/)
{
	RegConsoleCmd("sm_rank",		cmd_Ranks,			"[BF2] Pokazuje Informacje o Rankingu");
	RegConsoleCmd("sm_bf2stats",	cmd_Bf2Stats,		"[BF2] Pokazuje Statystyki Danej Broni");

	RegConsoleCmd("sm_bf2menu",		cmd_BF2Menu,		"[BF2] Menu serwera");
	RegConsoleCmd("sm_bf2",			cmd_BF2Menu,		"[BF2] Menu serwera");
	RegConsoleCmd("sm_menu",		cmd_BF2Menu,		"[BF2] Menu serwera");

	RegConsoleCmd("sm_bf2top",		cmd_BF2TOP,			"[BF2] TOP15");

	RegAdminCmd("sm_addbadge",		cmd_AdminAddBadge,	ADMFLAG_CONFIG);
	RegAdminCmd("sm_addkills",		cmd_AdminAddKills,	ADMFLAG_CONFIG);
}

public Action cmd_Ranks(int client, int args)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;

	MenuClientRanks(client);

	return Plugin_Continue;
}

public Action cmd_Bf2Stats(int client, int args)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;

	MenuClientStats(client, client);
	
	return Plugin_Continue;
}

public Action cmd_BF2Menu(int client, int args)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;

	MenuBF2(client);

	return Plugin_Continue;
}

public Action cmd_BF2TOP(int client, int args)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;

	MenuTOP15(client);

	return Plugin_Continue;
}


public Action cmd_AdminAddBadge(int client, int args)
{
	if ( args != 3 ) {
		PrintToConsole(client, "Usage: sm_addbadge <#id> <badge 0-7> <level 0-4>");
		return Plugin_Handled;
	}

	char szID[16], sBadge[4], sLevel[4];

	GetCmdArg(1, szID, sizeof(szID));
	GetCmdArg(2, sBadge, sizeof(sBadge));
	GetCmdArg(3, sLevel, sizeof(sLevel));

	StripQuotes(szID);
	StripQuotes(sBadge);
	StripQuotes(sLevel);

	int cBadge = StringToInt(sBadge);
	int cLevel = StringToInt(sLevel);

	if ( cBadge < 0 || cBadge > MAX_BADGES || cLevel < 0 || cLevel > LEVEL_PROFESIONAL )
		return Plugin_Handled;

	int id2 = FindTarget(client, szID, false, false);
	if ( id2 <= 0 )
		return Plugin_Handled;

	gClientInfo[id2].mBadges[cBadge] = cLevel;

	if ( client )
		BF2_PrintToChat(client, "tb admin add badge", id2, gBadgeName[cBadge][cLevel]);
	else
		PrintToServer("%N badge has been awarded to %t", id2, gBadgeName[cBadge][cLevel]);

	char sLang[4];
	gServerData.cVarOvLanguage.GetString(sLang, sizeof(sLang));
	if ( StrEqual(sLang, "pl") )
		LogMessage("[BF2-ADMIN] Admin %d awansował odznakę %t graczowi %d", 
		client ? GetSteamAccountID(client) : 0, gBadgeName[cBadge][cLevel], GetSteamAccountID(id2));
	else
		LogMessage("[BF2-ADMIN] Admin %d awarded badge %t to player %d", 
		client ? GetSteamAccountID(client) : 0, gBadgeName[cBadge][cLevel], GetSteamAccountID(id2));

	return Plugin_Handled;
}

public Action cmd_AdminAddKills(int client, int args)
{
	if ( args != 2 ) {
		PrintToConsole(client, "Usage: sm_addkills <#id> <kills>");
		return Plugin_Handled;
	}

	char szID[16], sKills[4];

	GetCmdArg(1, szID, sizeof(szID));
	GetCmdArg(2, sKills, sizeof(sKills));

	StripQuotes(szID);
	StripQuotes(sKills);

	int cKills = StringToInt(sKills);

	if ( cKills < 0 )
		return Plugin_Handled;

	int id2 = FindTarget(client, szID, false, false);
	if ( id2 <= 0 )
		return Plugin_Handled;

	gClientInfo[id2].Stats[KILL_ALL] = cKills;

	if ( client )
		BF2_PrintToChat(client, "tb admin set kills", id2, cKills);
	else
		PrintToServer("%N kills have been set to %d", id2, cKills);

	char sLang[4];
	gServerData.cVarOvLanguage.GetString(sLang, sizeof(sLang));
	if ( StrEqual(sLang, "pl") )
		LogMessage("[BF2-ADMIN] Admin %d ustawił graczowi %s (%d) %d fragów", 
		client ? GetSteamAccountID(client) : 0, id2, GetSteamAccountID(id2), cKills);
	else
		LogMessage("[BF2-ADMIN] Admin %d set %d kills to player %s (%d", 
		client ? GetSteamAccountID(client) : 0, cKills, id2, GetSteamAccountID(id2));

	BF_CheckRank(id2, false);

	return Plugin_Handled;
}

/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
// =============================================================//
// 																//
// 						MenuClientRanks							//
//																//
// 																//
// =============================================================//
public void MenuClientRanks(int client)
{
	char fMenu[256];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuClientRanks_H);

	Format(fMenu, sizeof(fMenu), "%t", "MenuClientRanksTitle", gRankName[gClientInfo[client].Rank], gClientInfo[client].Stats[KILL_ALL]);
	if ( gClientInfo[client].Rank < 17 ) {
		Format(fMenu, sizeof(fMenu), "%t", "MenuClientRanksTitle2", fMenu, gRankName[gClientInfo[client].Rank + 1]);
		Format(fMenu, sizeof(fMenu), "%t", "MenuClientRanksTitle3", fMenu, RoundFloat(gRankXP[gClientInfo[client].Rank + 1] * gServerData.cVarXpMultiplier.FloatValue));
	}

	mMenu.SetTitle(fMenu);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientRanksList");
	mMenu.AddItem("lists", fMenu);

	mMenu.Display(client, 30);
}
public int MenuClientRanks_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;
	else if ( mAction == MenuAction_Select )
	{
		char info[8];
		mMenu.GetItem(param, info, sizeof(info));

		if ( StrEqual(info, "lists") )
			MenuListRanks(client);
	}

	return 0;
}
// =============================================================//
// 						MenuListRanks							//
//																//
// =============================================================//
public void MenuListRanks(int client)
{
	char fMenu[128];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuListRanks_H);
	mMenu.SetTitle("%t", "MenuListRanksTitle");

	for(int i = 1; i < MAX_RANKS; i++)
	{
		FormatEx(fMenu, sizeof(fMenu), "%t", "MenuListRanksDesc", gRankName[i], RoundFloat(gRankXP[i] * gServerData.cVarXpMultiplier.FloatValue));
		mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	}

	mMenu.Display(client, 30);
}
public int MenuListRanks_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;

	return 0;
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
// =============================================================//
// 																//
// 						MenuClientStats							//
//																//
// 																//
// =============================================================//
public void MenuClientStats(int client, int who)
{
	int acc = RoundFloat( (float(gClientInfo[who].sHit) / float(gClientInfo[who].sShoot))* 100 );
	char fMenu[128];

	SetGlobalTransTarget(client);
	
	Menu mMenu = new Menu(MenuClientStats_H);
	FormatEx(fMenu, sizeof(fMenu), "MenuClientStatsTitle", who);
	mMenu.SetTitle(fMenu);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKills", gClientInfo[who].Stats[KILL_ALL]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsKnife", gClientInfo[who].Stats[KILL_KNIFE]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsPistol", gClientInfo[who].Stats[KILL_PISTOL]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsM249", gClientInfo[who].Stats[KILL_M249]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsSniper", gClientInfo[who].Stats[KILL_SNIPER]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsRifle", gClientInfo[who].Stats[KILL_RIFLE]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsShotgun", gClientInfo[who].Stats[KILL_SHOTGUN]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsSMG", gClientInfo[who].Stats[KILL_SMG]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsGrenade", gClientInfo[who].Stats[KILL_GRENADE]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsKillsAccuracy", acc);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsPlantBomb", gClientInfo[who].Stats[PLANT_BOMB]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsExplodedBomb", gClientInfo[who].Stats[EXPLODE_BOMB]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsDefuseBomb", gClientInfo[who].Stats[DEFUSE_BOMB]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsRank", gRankName[gClientInfo[who].Rank]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientStatsMedal", 
	gClientInfo[who].mMedal[MEDAL_GOLD], gClientInfo[who].mMedal[MEDAL_SILVER], gClientInfo[who].mMedal[MEDAL_BRONZE]);
	mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);

	mMenu.Display(client, 40);
}
public int MenuClientStats_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;
	
	return 0;
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
// =============================================================//
// 																//
// 							MenuBF2								//
//																//
// 																//
// =============================================================//
public void MenuBF2(int client)
{
	char fMenu[64];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuBF2_H);
	
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2Title");
	mMenu.SetTitle(fMenu);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2Help");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2Stats");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2PanelAdmin");
	mMenu.AddItem("", fMenu, CheckCommandAccess(client, "bf2_admin_panel", ADMFLAG_CONFIG) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	mMenu.Display(client, 30);
}
public int MenuBF2_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;
	else if ( mAction == MenuAction_Select )
	{
		switch(param)
		{
			case 0 :	MenuHelpBF2(client);
			case 1 :	MenuStatsBF2(client);
			case 2 :	MenuAdminBF2(client);
		}
	}

	return 0;
}

// =============================================================//
// 							MenuHelpBF2							//
//																//
// =============================================================//
public void MenuHelpBF2(int client)
{
	char fMenu[64];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuHelpBF2_H);
	
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpTitle");
	mMenu.SetTitle(fMenu);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge1");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge2");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge3");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge4");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge5");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge6");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge7");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBF2HelpBadge8");
	mMenu.AddItem("", fMenu);

	mMenu.ExitBackButton = true;
	mMenu.Display(client, 30);
}
public int MenuHelpBF2_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	switch(mAction)
	{
		case MenuAction_End :	delete mMenu;

		case MenuAction_Cancel : 
		{
			if ( param == MenuCancel_ExitBack )
				MenuBF2(client);
		}
		case MenuAction_Select :
		{
			gClientInfo[client].MenuSelect = param;
			MenuHelp_Badges(client, param);
		}
	}
	return 0;
}
// =============================================================//
// 							MenuHelp_Badges						//
//																//
// =============================================================//
public void MenuHelp_Badges(int client, int badge)
{
	char fMenu[256];

	SetGlobalTransTarget(client);
	
	Menu mMenu = new Menu(MenuHelp_Badges_H);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuHelpBadgesTitle", gBadgeInfo[badge]);
	mMenu.SetTitle(fMenu);

	for(int i = 1; i < 5; i++)
	{
		FormatEx(fMenu, sizeof(fMenu), "%t", gBadgeName[badge][i]);
		mMenu.AddItem("", fMenu);
	}

	mMenu.ExitBackButton = true;
	mMenu.Display(client, 30);
}
public int MenuHelp_Badges_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	switch(mAction)
	{
		case MenuAction_End :	delete mMenu;

		case MenuAction_Cancel : 
		{
			if ( param == MenuCancel_ExitBack )
				MenuHelpBF2(client);
		}
		case MenuAction_Select :
		{
			param ++;
			MenuBadgesInfo(client, param);
		}
	}
	
	return 0;
}
// =============================================================//
// 							MenuBadgesInfo						//
//																//
// =============================================================//
public void MenuBadgesInfo(int client, int item)
{
	char fMenu[256];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuBadgesInfo_H);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuBadgesInfoTitle", 
	gBadgeName[gClientInfo[client].MenuSelect][item],
	gBadgeInfoRequirements[gClientInfo[client].MenuSelect][item]);
	mMenu.SetTitle(fMenu);

	FormatEx(fMenu, sizeof(fMenu), "%t", gBadgeInfoAwards[gClientInfo[client].MenuSelect][item]);
	mMenu.AddItem("", fMenu);

	mMenu.Display(client, 40);
}
public int MenuBadgesInfo_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;
	else if ( mAction == MenuAction_Select )
		MenuHelp_Badges(client, gClientInfo[client].MenuSelect);
	
	return 0;
}

// =============================================================//
// 							MenuStatsBF2						//
//																//
// =============================================================//
public void MenuStatsBF2(int client)
{
	char fMenu[64];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuStatsBF2_H);
	
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuStatsBF2Title");
	mMenu.SetTitle(fMenu);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuStatsBF2ListPlayers");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuStatsBF2ClientBadges");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuStatsBF2ClientStats");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuStatsBF2ServerStats");
	mMenu.AddItem("", fMenu);

	mMenu.ExitBackButton = true;
	mMenu.Display(client, 30);
}
public int MenuStatsBF2_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	switch(mAction)
	{
		case MenuAction_End :	delete mMenu;

		case MenuAction_Cancel : 
		{
			if ( param == MenuCancel_ExitBack )
				MenuBF2(client);
		}
		case MenuAction_Select :
		{
			switch(param)
			{
				case 0 :	MenuPlayersList(client);
				case 1 :	MenuClientBadges(client, client);
				case 2 :	MenuClientRanks(client);
				case 3 :	MenuTOP15(client);
			}
		}
	}
	return 0;
}
// =============================================================//
// 							MenuPlayersList						//
// =============================================================//
public void MenuPlayersList(int client)
{
	char pName[MAX_NICKNAME], uID[10], fMenu[32];
	bool find = false;

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuPlayersList_H);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuPlayersListTitle");
	mMenu.SetTitle(fMenu);

	LoopClients(pID)
	{
		if ( IsFakeClient(pID) || client == pID )
			continue;

		find = true;
		
		GetClientName(pID, pName, sizeof(pName));
		IntToString(GetClientUserId(pID), uID, sizeof(uID));
		mMenu.AddItem(uID, pName);
	}

	if ( !find ) {
		FormatEx(fMenu, sizeof(fMenu), "%t", "MenuPlayerListNoPlayers");
		mMenu.AddItem(uID, fMenu, ITEMDRAW_DISABLED);
	}

	mMenu.Display(client, 30);
}
public int MenuPlayersList_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;
	else if ( mAction == MenuAction_Select )
	{
		char info[10];
		mMenu.GetItem(param, info, sizeof(info));
		int id2 = GetClientOfUserId(StringToInt(info));

		if ( !IsValidClient(id2) ) {
			BF2_PrintToChat(client, "tb player disconnected");
			return 0;
		}

		MenuClientBadges(client, id2);
	}
	return 0;
}
public void MenuTOP15(int client)
{
	char fQuery[128];
	FormatEx(fQuery, sizeof(fQuery), "SELECT `player_name`, `kills` FROM `bf2_players` ORDER BY `kills` DESC LIMIT 15;");
	gServerData.DBK.Query(MenuTOP15_S, fQuery, GetClientUserId(client));
}

public void MenuTOP15_S(Database db, DBResultSet results, const char[] sError, int clientID)
{
	int client = GetClientOfUserId(clientID);

	if ( !IsValidClient(client) )
		return;

	if ( db == null || results == null ) {
		LogToFile(FILELOG_ERROR, "[ERROR SQL] sql_LoadDataClientH : %s", sError);
		return;
	}

	if ( !results.RowCount )
		return;

	char pName[MAX_NICKNAME], fMenu[128];
	int kills;

	Menu mMenu = new Menu(MenuTOP15_H);
	mMenu.SetTitle("TOP15:");


	while(results.FetchRow())
	{
		results.FetchString(0, pName, sizeof(pName));
		kills = results.FetchInt(1);

		FormatEx(fMenu, sizeof(fMenu), "%s [%d frags]", pName, kills);
		mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	}

	mMenu.Display(client, 30);
}
public int MenuTOP15_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;
	return 0;
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
// =============================================================//
// 																//
// 							MenuClientBadges					//
//					Menu ze statystykami odznak gracza			//
// 																//
// =============================================================//
public void MenuClientBadges(int client, int who)
{
	char fMenu[128];
	bool find = false;

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuClientBadges_H);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuClientBadgesTitle", who, gRankName[gClientInfo[who].Rank], gClientInfo[who].Stats[KILL_ALL]);
	mMenu.SetTitle(fMenu);

	for(int i = 0; i < MAX_BADGES ; i++)
	{
		if ( gClientInfo[who].mBadges[i] == 0 )
			continue;
		
		FormatEx(fMenu, sizeof(fMenu), "%t", gBadgeName[i][gClientInfo[who].mBadges[i]]);
		mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);//(client == who ? ITEMDRAW_DEFAULT: ITEMDRAW_DISABLED));
		find = true;
	}

	if ( !find ) {
		FormatEx(fMenu, sizeof(fMenu), "MenuClientBadgesNoBadges");
		mMenu.AddItem("", fMenu, ITEMDRAW_DISABLED);
	}

	mMenu.Display(client, 30);
}
public int MenuClientBadges_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;

	return 0;
}


// =============================================================//
// 							MenuAdminBF2						//
//																//
// =============================================================//
public void MenuAdminBF2(int client)
{
	char fMenu[64];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuAdminBF2_H);
	
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuAdminBF2Title");
	mMenu.SetTitle(fMenu);

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuAdminBF2Reset");
	mMenu.AddItem("33", fMenu);

	mMenu.ExitBackButton = true;
	mMenu.Display(client, 30);
}
public int MenuAdminBF2_H(Menu mMenu, MenuAction mAction, int client, int param)
{
	switch(mAction)
	{
		case MenuAction_End :	delete mMenu;

		case MenuAction_Cancel : 
		{
			if ( param == MenuCancel_ExitBack )
				MenuBF2(client);
		}
		case MenuAction_Select :
		{
			if ( !CheckCommandAccess(client, "bf2_admin_panel", ADMFLAG_CONFIG) )
				return 0;

			char info[4];
			mMenu.GetItem(param, info, sizeof(info));
			int item = StringToInt(info);

			if ( item == 33 )
				MenuAdminBF2_ConfirmReset(client);
		}
	}
	return 0;
}
// =============================================================//
// 					MenuAdminBF2_ConfirmReset					//
// =============================================================//
public void MenuAdminBF2_ConfirmReset(int client)
{
	char fMenu[64];

	SetGlobalTransTarget(client);

	Menu mMenu = new Menu(MenuAdminBF2_ConfirmResetH);
	mMenu.SetTitle("%t", "MenuAdminBF2Reset_TITLE");

	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuAdminBF2Reset_NO");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuAdminBF2Reset_NO");
	mMenu.AddItem("", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuAdminBF2Reset_YES");
	mMenu.AddItem("33", fMenu);
	FormatEx(fMenu, sizeof(fMenu), "%t", "MenuAdminBF2Reset_NO");
	mMenu.AddItem("", fMenu);

	mMenu.Display(client, 30);
}
public int MenuAdminBF2_ConfirmResetH(Menu mMenu, MenuAction mAction, int client, int param)
{
	if ( mAction == MenuAction_End )
		delete mMenu;
	else if ( mAction == MenuAction_Select ) {
		char info[4];
		mMenu.GetItem(param, info, sizeof(info));
		int item = StringToInt(info);

		if ( item == 33 )
		{
			char fQuery[1024];
			FormatEx(fQuery, sizeof(fQuery), "TRUNCATE TABLE `bf2_players`;");
			if ( !SQL_FastQuery(gServerData.DBK, fQuery, sizeof(fQuery)) ) {
				char Error[256];
				SQL_GetError(gServerData.DBK, Error, sizeof(Error));
				LogToFile(FILELOG_ERROR, "[ERROR SQL] MenuAdminBF2_ConfirmResetH: %s", Error);

				PrintToChat(client, "ERROR");
				return 0;
			}

			ServerCommand("mp_restartgame 2");

			BF2_PrintToChat(client, "tb reset database");
			LoopClients(pID)
			{
				gClientInfo[pID].ResetVars(/*void*/);
				sql_LoadDataClient(pID);
			}
		}
	}
	return 0;
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
public void BF_CheckRank(int client, bool load_data)
{
	bool level_up = false;

	while(
		gClientInfo[client].Rank < MAX_RANKS && 
		gClientInfo[client].Stats[KILL_ALL] >= RoundFloat(gRankXP[gClientInfo[client].Rank + 1] * gServerData.cVarXpMultiplier.FloatValue) 
	)
	{
		gClientInfo[client].Rank ++;
		level_up = true;
	}

	if ( !load_data && level_up )
	{
		EmitSoundToClient(client, SND_LEVELUP, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
		
		if ( gClientInfo[client].Rank < MAX_RANKS )
			BF2_PrintToChat(client, "tb new level rank", gRankName[gClientInfo[client].Rank]);
	}
}

public void Check_Badges(int client)
{
	switch(gClientInfo[client].mBadges[BADGE_KNIFE])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].sKillsRound[BADGE_KNIFE] >= 2 ) {
				gClientInfo[client].mBadges[BADGE_KNIFE] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_KNIFE][LEVEL_BASIC]);
				BF2_CreateOverlay(client, KNIFE_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( gClientInfo[client].Stats[KILL_KNIFE] >= 50 ) {
				gClientInfo[client].mBadges[BADGE_KNIFE] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_KNIFE][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, KNIFE_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( gClientInfo[client].Stats[KILL_KNIFE] >= 100 || gClientInfo[client].sKillsRound[BADGE_KNIFE] >= 3 ) {
				gClientInfo[client].mBadges[BADGE_KNIFE] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_KNIFE][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, KNIFE_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( gClientInfo[client].Stats[KILL_KNIFE] >= 200 || gClientInfo[client].sKillsRound[BADGE_KNIFE] >= 5 ) {
				gClientInfo[client].mBadges[BADGE_KNIFE] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_KNIFE][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, KNIFE_PROFESIONAL);
			}
		}
	}

	switch(gClientInfo[client].mBadges[BADGE_PISTOL])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].sKillsRound[BADGE_PISTOL] >= 3 ) {
				gClientInfo[client].mBadges[BADGE_PISTOL] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_PISTOL][LEVEL_BASIC]);
				BF2_CreateOverlay(client, PISTOL_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( gClientInfo[client].Stats[KILL_PISTOL] >= 100 ) {
				gClientInfo[client].mBadges[BADGE_PISTOL] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_PISTOL][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, PISTOL_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( 
				gClientInfo[client].Stats[KILL_PISTOL] >= 200 || gClientInfo[client].sKillsRound[BADGE_PISTOL] >= 4 ||
				gClientInfo[client].sKillsHSRound[BADGE_PISTOL] >= 2
			) {
				gClientInfo[client].mBadges[BADGE_PISTOL] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_PISTOL][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, PISTOL_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( 
				gClientInfo[client].Stats[KILL_PISTOL] >= 400 || gClientInfo[client].sKillsRound[BADGE_PISTOL] >= 6 ||
				gClientInfo[client].sKillsHSRound[BADGE_PISTOL] >= 3
			) {
				gClientInfo[client].mBadges[BADGE_PISTOL] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_PISTOL][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, PISTOL_PROFESIONAL);
			}
		}
	}

	int acc = RoundFloat( (float(gClientInfo[client].sHit) / float(gClientInfo[client].sShoot))* 100 );
	switch(gClientInfo[client].mBadges[BADGE_ASSAULT])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].sKillsRound[BADGE_ASSAULT] >= 4 ) {
				gClientInfo[client].mBadges[BADGE_ASSAULT] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_ASSAULT][LEVEL_BASIC]);
				BF2_CreateOverlay(client, RIFLE_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( acc >= 25 ) {
				gClientInfo[client].mBadges[BADGE_ASSAULT] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_ASSAULT][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, RIFLE_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( 
				gClientInfo[client].Stats[KILL_ALL] >= 2000 || gClientInfo[client].sKillsRound[BADGE_ASSAULT] >= 5 ||
				gClientInfo[client].sKillsHSRound[BADGE_ASSAULT] >= 3
			) {
				gClientInfo[client].mBadges[BADGE_ASSAULT] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_ASSAULT][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, RIFLE_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( 
				gClientInfo[client].Stats[KILL_ALL] >= 4000 || gClientInfo[client].sKillsRound[BADGE_ASSAULT] >= 7 ||
				gClientInfo[client].sKillsHSRound[BADGE_ASSAULT] >= 5
			) {
				gClientInfo[client].mBadges[BADGE_ASSAULT] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_ASSAULT][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, RIFLE_PROFESIONAL);
			}
		}
	}
	
	switch(gClientInfo[client].mBadges[BADGE_SNIPER])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].sKillsRound[BADGE_SNIPER] >= 3 ) {
				gClientInfo[client].mBadges[BADGE_SNIPER] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SNIPER][LEVEL_BASIC]);
				BF2_CreateOverlay(client, SNIPER_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( gClientInfo[client].Stats[KILL_SNIPER] >= 100 ) {
				gClientInfo[client].mBadges[BADGE_SNIPER] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SNIPER][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, SNIPER_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( 
				gClientInfo[client].Stats[KILL_SNIPER] >= 200 || gClientInfo[client].sKillsRound[BADGE_SNIPER] >= 4 ||
				gClientInfo[client].sKillsHSRound[BADGE_SNIPER - 1] >= 1
			) {
				gClientInfo[client].mBadges[BADGE_SNIPER] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SNIPER][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, SNIPER_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( 
				gClientInfo[client].Stats[KILL_SNIPER] >= 400 || gClientInfo[client].sKillsRound[BADGE_SNIPER] >= 6 ||
				gClientInfo[client].sKillsHSRound[BADGE_SNIPER - 1] >= 3
			) {
				gClientInfo[client].mBadges[BADGE_SNIPER] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SNIPER][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, SNIPER_PROFESIONAL);
			}
		}
	}
	
	switch(gClientInfo[client].mBadges[BADGE_SUPPORT])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].sKillsRound[BADGE_SUPPORT] >= 2 ) {
				gClientInfo[client].mBadges[BADGE_SUPPORT] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SUPPORT][LEVEL_BASIC]);
				BF2_CreateOverlay(client, M249_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( gClientInfo[client].Stats[KILL_M249] >= 100 ) {
				gClientInfo[client].mBadges[BADGE_SUPPORT] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SUPPORT][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, M249_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( 
				gClientInfo[client].Stats[KILL_M249] >= 200 || gClientInfo[client].sKillsRound[BADGE_SUPPORT] >= 4 ||
				gClientInfo[client].sKillsHSRound[BADGE_SUPPORT - 1] >= 1
			) {
				gClientInfo[client].mBadges[BADGE_SUPPORT] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SUPPORT][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, M249_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( 
				gClientInfo[client].Stats[KILL_M249] >= 400 || gClientInfo[client].sKillsRound[BADGE_SUPPORT] >= 6 ||
				gClientInfo[client].sKillsHSRound[BADGE_SUPPORT - 1] >= 3
			) {
				gClientInfo[client].mBadges[BADGE_SUPPORT] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SUPPORT][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, M249_PROFESIONAL);
			}
		}
	}
	
	switch(gClientInfo[client].mBadges[BADGE_EXPLOSIVES])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].Stats[KILL_GRENADE] >= 30 ) {
				gClientInfo[client].mBadges[BADGE_EXPLOSIVES] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_EXPLOSIVES][LEVEL_BASIC]);
				BF2_CreateOverlay(client, EXPLOSIVES_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( gClientInfo[client].Stats[KILL_GRENADE] >= 100 ) {
				gClientInfo[client].mBadges[BADGE_EXPLOSIVES] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_EXPLOSIVES][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, EXPLOSIVES_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( gClientInfo[client].Stats[KILL_GRENADE] >= 200 ) {
				gClientInfo[client].mBadges[BADGE_EXPLOSIVES] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_EXPLOSIVES][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, EXPLOSIVES_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( gClientInfo[client].Stats[KILL_GRENADE] >= 500 ) {
				gClientInfo[client].mBadges[BADGE_EXPLOSIVES] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_EXPLOSIVES][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, EXPLOSIVES_PROFESIONAL);
			}
		}
	}
	
	switch(gClientInfo[client].mBadges[BADGE_SHOTGUN])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].sKillsRound[BADGE_SHOTGUN - 1] >= 3 ) {
				gClientInfo[client].mBadges[BADGE_SHOTGUN] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SHOTGUN][LEVEL_BASIC]);
				BF2_CreateOverlay(client, SHOTGUN_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( gClientInfo[client].Stats[KILL_SHOTGUN] >= 100 ) {
				gClientInfo[client].mBadges[BADGE_SHOTGUN] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SHOTGUN][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, SHOTGUN_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( 
				gClientInfo[client].Stats[KILL_SHOTGUN] >= 200 || gClientInfo[client].sKillsRound[BADGE_SHOTGUN - 1] >= 4 ||
				gClientInfo[client].sKillsHSRound[BADGE_SHOTGUN - 2] >= 1
			) {
				gClientInfo[client].mBadges[BADGE_SHOTGUN] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SHOTGUN][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, SHOTGUN_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( 
				gClientInfo[client].Stats[KILL_SHOTGUN] >= 500 || gClientInfo[client].sKillsRound[BADGE_SHOTGUN - 1] >= 6 ||
				gClientInfo[client].sKillsHSRound[BADGE_SHOTGUN - 2] >= 3
			) {
				gClientInfo[client].mBadges[BADGE_SHOTGUN] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SHOTGUN][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, SHOTGUN_PROFESIONAL);
			}
		}
	}
	
	switch(gClientInfo[client].mBadges[BADGE_SMG])
	{
		case LEVEL_NONE :
		{
			if ( gClientInfo[client].sKillsRound[BADGE_SMG - 1] >= 3 ) {
				gClientInfo[client].mBadges[BADGE_SMG] = LEVEL_BASIC;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SMG][LEVEL_BASIC]);
				BF2_CreateOverlay(client, SMG_BASIC);
			}
		}
		case LEVEL_BASIC :
		{
			if ( gClientInfo[client].Stats[KILL_SMG] >= 100 ) {
				gClientInfo[client].mBadges[BADGE_SMG] = LEVEL_VETERAN;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SMG][LEVEL_VETERAN]);
				BF2_CreateOverlay(client, SMG_VETERAN);
			}
		}
		case LEVEL_VETERAN :
		{
			if ( 
				gClientInfo[client].Stats[KILL_SMG] >= 200 || gClientInfo[client].sKillsRound[BADGE_SMG - 1] >= 4 ||
				gClientInfo[client].sKillsHSRound[BADGE_SMG - 2] >= 1
			) {
				gClientInfo[client].mBadges[BADGE_SMG] = LEVEL_EXPERT;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SMG][LEVEL_EXPERT]);
				BF2_CreateOverlay(client, SMG_EXPERT);
			}
		}
		case LEVEL_EXPERT :
		{
			if ( 
				gClientInfo[client].Stats[KILL_SMG] >= 450 || gClientInfo[client].sKillsRound[BADGE_SMG - 1] >= 6 ||
				gClientInfo[client].sKillsHSRound[BADGE_SMG - 2] >= 3
			) {
				gClientInfo[client].mBadges[BADGE_SMG] = LEVEL_PROFESIONAL;
				BF2_PrintToChat(client, "tb new badges", gBadgeName[BADGE_SMG][LEVEL_PROFESIONAL]);
				BF2_CreateOverlay(client, SMG_PROFESIONAL);
			}
		}
	}
}

public void SortByFrags()
{
	gServerData.TopFrags[0] = 0;
	gServerData.TopFrags[1] = 0;
	gServerData.TopFrags[2] = 0;

	LoopClients(pID)
	{
		for(int tf = 0; tf < 3; tf++)
		{
			if ( gClientInfo[pID].sFrags > gClientInfo[gServerData.TopFrags[tf]].sFrags ) 
			{
				if ( tf == 0 )  {
					if (gServerData.TopFrags[1] > 0) gServerData.TopFrags[2] = gServerData.TopFrags[1];
					if (gServerData.TopFrags[0] > 0) gServerData.TopFrags[1] = gServerData.TopFrags[0];
				} 
				else if ( tf == 1 )
					if ( gServerData.TopFrags[1] > 0 ) gServerData.TopFrags[2] = gServerData.TopFrags[1];

				gServerData.TopFrags[tf] = pID;
				break;
			}
		}
	}
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
public Action Timer_RemoveFrozen(Handle timer, const int clientID)
{
	int client = GetClientOfUserId(clientID);

	if ( client ) {
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, gInvisAlphaValue[gClientInfo[client].mBadges[BADGE_SHOTGUN]]);
	}
}

public Action Timer_RemoveOverlay(Handle timer, const int clientID)
{
	int client = GetClientOfUserId(clientID);

	if ( client ) {
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") &~ FCVAR_CHEAT);
		ClientCommand(client, "r_screenoverlay \"\"");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
	}

}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
void onMapDownload(/*void*/)
{
	PrecacheSound(SND_LEVELUP, true);

	BF2_Download(KNIFE_BASIC);
	BF2_Download(KNIFE_VETERAN);
	BF2_Download(KNIFE_EXPERT);
	BF2_Download(KNIFE_PROFESIONAL);
	BF2_Download(PISTOL_BASIC);
	BF2_Download(PISTOL_VETERAN);
	BF2_Download(PISTOL_EXPERT);
	BF2_Download(PISTOL_PROFESIONAL);
	BF2_Download(RIFLE_BASIC);
	BF2_Download(RIFLE_VETERAN);
	BF2_Download(RIFLE_EXPERT);
	BF2_Download(RIFLE_PROFESIONAL);
	BF2_Download(SNIPER_BASIC);
	BF2_Download(SNIPER_VETERAN);
	BF2_Download(SNIPER_EXPERT);
	BF2_Download(SNIPER_PROFESIONAL);
	BF2_Download(M249_BASIC);
	BF2_Download(M249_VETERAN);
	BF2_Download(M249_EXPERT);
	BF2_Download(M249_PROFESIONAL);
	BF2_Download(EXPLOSIVES_BASIC);
	BF2_Download(EXPLOSIVES_VETERAN);
	BF2_Download(EXPLOSIVES_EXPERT);
	BF2_Download(EXPLOSIVES_PROFESIONAL);
	BF2_Download(SHOTGUN_BASIC);
	BF2_Download(SHOTGUN_VETERAN);
	BF2_Download(SHOTGUN_EXPERT);
	BF2_Download(SHOTGUN_PROFESIONAL);
	BF2_Download(SMG_BASIC);
	BF2_Download(SMG_VETERAN);
	BF2_Download(SMG_EXPERT);
	BF2_Download(SMG_PROFESIONAL);
}
/*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
/*					*/
bool IsValidClient(int client)
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
		return false;

	return true;
}
/*					*/
void BF2_FormatColor(char[] sText, const int iMaxlen)
{
	Format(sText, iMaxlen, " @darkblue%s @default%s", "● [BF2]", sText);

	ReplaceString(sText, iMaxlen, "@default", "\x01");
	ReplaceString(sText, iMaxlen, "@red", "\x02");
	ReplaceString(sText, iMaxlen, "@lgreen", "\x03");
	ReplaceString(sText, iMaxlen, "@green", "\x04");
	ReplaceString(sText, iMaxlen, "@lime", "\x06");
	ReplaceString(sText, iMaxlen, "@grey", "\x0A");
	ReplaceString(sText, iMaxlen, "@darkblue", "\x0C");
	ReplaceString(sText, iMaxlen, "@orange", "\x10");
	ReplaceString(sText, iMaxlen, "@orchid", "\x0E");
	ReplaceString(sText, iMaxlen, "@grey2", "\x0D");
	ReplaceString(sText, iMaxlen, "@ct", "\x0B");
	ReplaceString(sText, iMaxlen, "@tt", "\x09");
}
/*					*/
void BF2_PrintToChat(int client, any ...)
{
    if ( !IsFakeClient(client) )
    {
        SetGlobalTransTarget(client);

        static char sText[192];
        VFormat(sText, 192, "%t", 2);

        BF2_FormatColor(sText, 192);

        PrintToChat(client, sText);
    }
}
/*					*/
void BF2_TranslationPrintToChatAll(any ...)
{
    LoopClients(pID)
    {
        if ( !IsFakeClient(pID) )
        {
            SetGlobalTransTarget(pID);
            
            static char sText[192];
            VFormat(sText, 102, "%t", 1);
            
            BF2_FormatColor(sText, 192);
            
            PrintToChat(pID, sText);
        }
    }
}
/*					*/
void BF2_CreateOverlay(int client, char[] ovName)
{
	char sLang[4];
	gServerData.cVarOvLanguage.GetString(sLang, sizeof(sLang));
	
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") &~ FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"bf2mod_csc/%s/%s\"", sLang, ovName);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);

	CreateTimer(gServerData.cVarScreenTime.FloatValue, Timer_RemoveOverlay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
/*					*/
void BF2_Download(char[] sName)
{
	char fMat[64], sLang[4];
	gServerData.cVarOvLanguage.GetString(sLang, sizeof(sLang));

	Format(fMat, sizeof(fMat), "materials/bf2mod_csc/%s/%s.vtf", sLang, sName);
	PrecacheGeneric(fMat, true);
	AddFileToDownloadsTable(fMat);

	Format(fMat, sizeof(fMat), "materials/bf2mod_csc/%s/%s.vmt", sLang, sName);
	PrecacheGeneric(fMat, true);
	AddFileToDownloadsTable(fMat);
}