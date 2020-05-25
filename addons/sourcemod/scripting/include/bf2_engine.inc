#define MAX_NICKNAME 64
#define LoopClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if ( IsClientInGame(%1) )

#define MAX_RANKS 17
#define MAX_BADGES 8

#define LEVEL_NONE 0
#define LEVEL_BASIC 1
#define LEVEL_VETERAN 2
#define LEVEL_EXPERT 3
#define LEVEL_PROFESIONAL 4

#define BADGE_KNIFE 0
#define BADGE_PISTOL 1
#define BADGE_ASSAULT 2
#define BADGE_SNIPER 3
#define BADGE_SUPPORT 4
#define BADGE_EXPLOSIVES 5
#define BADGE_SHOTGUN 6
#define BADGE_SMG 7

#define KILL_ALL 0
#define KILL_KNIFE 1
#define KILL_PISTOL 2
#define KILL_M249 3
#define KILL_SNIPER 4
#define KILL_RIFLE 5
#define KILL_SHOTGUN 6
#define KILL_SMG 7
#define KILL_GRENADE 8
#define PLANT_BOMB 10
#define EXPLODE_BOMB 11
#define DEFUSE_BOMB 12

#define MEDAL_GOLD 0
#define MEDAL_SILVER 1
#define MEDAL_BRONZE 2

#define SND_LEVELUP "bf2_csc/levelup.mp3"

#define KNIFE_BASIC "knife_basic"
#define KNIFE_VETERAN "knife_veteran"
#define KNIFE_EXPERT "knife_expert"
#define KNIFE_PROFESIONAL "knife_profesional"

#define PISTOL_BASIC "pistol_basic."
#define PISTOL_VETERAN "pistol_veteran"
#define PISTOL_EXPERT "pistol_expert"
#define PISTOL_PROFESIONAL "pistol_profesional"

#define RIFLE_BASIC "rifle_basic"
#define RIFLE_VETERAN "rifle_veteran"
#define RIFLE_EXPERT "rifle_expert"
#define RIFLE_PROFESIONAL "rifle_profesional"

#define SNIPER_BASIC "sniper_basic"
#define SNIPER_VETERAN "sniper_veteran"
#define SNIPER_EXPERT "sniper_expert"
#define SNIPER_PROFESIONAL "sniper_profesional"

#define M249_BASIC "m249_basic"
#define M249_VETERAN "m249_veteran"
#define M249_EXPERT "m249_expert"
#define M249_PROFESIONAL "m249_profesional"

#define EXPLOSIVES_BASIC "explosives_basic"
#define EXPLOSIVES_VETERAN "explosives_veteran"
#define EXPLOSIVES_EXPERT "explosives_expert"
#define EXPLOSIVES_PROFESIONAL "explosives_profesional"

#define SHOTGUN_BASIC "shotgun_basic"
#define SHOTGUN_VETERAN "shotgun_veteran"
#define SHOTGUN_EXPERT "shotgun_expert"
#define SHOTGUN_PROFESIONAL "shotgun_profesional"

#define SMG_BASIC "smg_basic"
#define SMG_VETERAN "smg_veteran"
#define SMG_EXPERT "smg_expert"
#define SMG_PROFESIONAL "smg_profesional"
