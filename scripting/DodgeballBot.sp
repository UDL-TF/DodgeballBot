#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#include <multicolors>
#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Dodgeball Bot"
#define PLUGIN_AUTHOR      "Nebula"
#define PLUGIN_DESCIPTION  "A practice bot for dodgeball."
#define PLUGIN_VERSION     "1.0.8"
#define PLUGIN_URL         "-"

#define AnalogueTeam(%1) (%1^1)	//https://github.com/Mikah31/TFDB-NerSolo

bool g_bEnable = false;

int g_iBot = -1;
int g_iWeapon = -1;
int g_iDeflectRadius = 750;
int g_iCriticalDefRadius = 100;
int g_iBotMoveDistance = 400;
int g_iCurrentPlayer = -1;

float g_fRandomAngle = 180.0;
float g_fGlobalAngle[3];
float g_fTargetPositions[2][3];
float g_fRandomPosition[3];
float g_fDragTimeMax;
float g_fTime;

bool g_bChoiceAngle 	= false;
bool g_bAttack 			= false;
bool g_bDeflectPause 	= true;
bool g_bBotFixed		= false;
bool g_bOrbit			= false;
bool g_bTrackRocket		= false;
bool g_bFlick			= false;

float g_fPVBVoteTime = 0.0;

char g_strBotName[MAX_NAME_LENGTH];
int 	g_iDeflectRadiusMin;
int 	g_iDeflectRadiusMax;
float 	g_fDragXMin;
float 	g_fDragXMax;
float   g_fDragYMin;
float   g_fDragYMax;
float   g_fOrbitTimeMin;
float   g_fOrbitTimeMax;
float   g_fOrbitAngleMin;
float   g_fOrbitAngleMax;
float 	g_fOrbitDegree;
float	g_fAvoidRocketAngle;
float   g_fOrbitMaxRocketSpeed;

ConVar g_CvarPVBenable;
ConVar g_CvarVoteCooldown;
ConVar g_CvarBotTeam;
ConVar g_CvarBotAutoJoin;
ConVar g_CvarCleanBotsWhenInactive;

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description = PLUGIN_DESCIPTION,
	version 	= PLUGIN_VERSION,
	url 		= PLUGIN_URL
};

public void OnPluginStart()
{
	RegAdminCmd("sm_pvb", PVB_Cmd, ADMFLAG_GENERIC, "Toggle command for dodgeball bot.");
	RegAdminCmd("sm_pvb_reloadcfg", PVB_ReloadCfg, ADMFLAG_GENERIC, "Reloads the bot config.");
	RegConsoleCmd("sm_votepvb", VotePvB_Cmd);

	g_CvarPVBenable 	= CreateConVar("tf_dodgeball_bot_enable", "1", "Enable/disable player vs bot mode.", _ ,true, 0.0, true, 1.0);
	g_CvarVoteCooldown 	= CreateConVar("tf_dodgeball_bot_vote_cooldown", "120", "Cooldown time for the voting command.", _, true, 0.0);
	g_CvarBotTeam 		= CreateConVar("tf_dodgeball_bot_team", "3", "The default team for the bot, 2 - Red, 3 - Blu.", _, true, 2.0, true, 3.0);
	g_CvarBotAutoJoin 	= CreateConVar("tf_dodgeball_bot_autojoin", "1", "Enable/ disable autojoin for bot when a player joins the server.", _, true, 0.0, true, 1.0);
	g_CvarCleanBotsWhenInactive = CreateConVar("tf_dodgeball_bot_cleanbots", "1", "Should this plugin kick bots when it's not active?", _, true, 0.0, true, 1.0);

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("object_deflected", OnObjectDeflected);

	LoadTranslations("tfdb.phrases.txt");

	g_fPVBVoteTime = 0.0;
}

public void OnConfigsExecuted()
{
	if (TFDB_IsDodgeballEnabled() && g_CvarPVBenable.BoolValue)
	{
		ParseConfig();

		g_fPVBVoteTime = 0.0;
	}
}

public void OnMapEnd()
{
	if (g_bEnable)
	{
		DisableMode();
	}
}

public void OnClientDisconnect(int iClient)
{
	if (g_bEnable)
	{
		if (iClient == g_iBot || GetRealClientCount(false) == 0)
		{
			DisableMode();
		}
		else if (iClient == g_iCurrentPlayer)	//This is to ensure that the bot doesn't try to mimic a disconnected player
		{
			g_iCurrentPlayer = -1;
		}
	}
}

public void OnClientConnected(int iClient)
{
	if (g_CvarBotAutoJoin.BoolValue && !g_bEnable && GetRealClientCount(false) == 1)
	{
		EnableMode();
	}
}

public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!g_bEnable)
	{
		if (g_CvarCleanBotsWhenInactive.BoolValue)
			CleanBots();
	}
	else
	{
		if (IsValidClient(iClient))
		{
			if (GetClientTeam(iClient) == g_CvarBotTeam.IntValue)
				ChangeClientTeam(iClient, AnalogueTeam(g_CvarBotTeam.IntValue));
		}
		else
		{
			g_iBot = iClient;

			ChangeClientTeam(iClient, g_CvarBotTeam.IntValue);
			SetEntityGravity(iClient, 400.0);
			SetEntProp(g_iBot, Prop_Data, "m_takedamage", 1, 1);
			g_iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		}
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (g_bAttack && iClient == g_iBot && g_iWeapon != -1)
	{
		SetEntPropFloat(g_iWeapon, Prop_Send, "m_flNextSecondaryAttack", 0.0);

		iButtons |= IN_ATTACK2;
	}

	return Plugin_Continue;
}

public void OnObjectDeflected(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (!g_bEnable) return;

	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (iClient != g_iBot) return;

	g_bFlick = true;

	Flick();

	g_fTime = GetEngineTime();

	// reset the deflect radius to prevent other shots to be missed
	g_iCriticalDefRadius = 100;
	g_iDeflectRadius = 285;
	g_bOrbit = false;
	g_bTrackRocket = true;
}

// ------------------ [Core function] -----------------------------
public void OnGameFrame()
{
	if (!g_bEnable && g_iBot == -1) return;

	float fBotPosition[3], fRocketPosition[3];
	g_bAttack = false;

	if (g_fTime + g_fDragTimeMax <= GetEngineTime())
	{
		g_bFlick = false;
	}

	int iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1) // I used the same method to spin through valid rockets as in the dodgeball plugin
	{
		int iRocket = TFDB_GetRocketEntity(iIndex);

		GetClientEyePosition(g_iBot, fBotPosition);
		GetEntPropVector(iRocket, Prop_Send, "m_vecOrigin", fRocketPosition);

		g_fDragTimeMax = TFDB_GetRocketClassDragTimeMax(TFDB_GetRocketClass(iIndex));

		if (!g_bDeflectPause)
		{
			float fAngle = 0.0, fPlayerpos[3];
			fPlayerpos = NULL_VECTOR;

			CreateTimer(0.1, Timer_ResetState); // I don't know why we have to wait 0.1 but ig it works

			if (g_iCurrentPlayer != -1)
			{
				GetClientAbsOrigin(g_iCurrentPlayer, fPlayerpos);

				if (GetVectorDistance(fBotPosition, fRocketPosition) <= GetVectorDistance(fBotPosition, fPlayerpos) * 0.45)
				{
					fAngle = GetAngleToTarget(g_iBot, iRocket);
				}
			}

			//CPrintToChatAll("bot to rocket angle: %.4f", fAngle);

			RocketState iRocketState = TFDB_GetRocketState(iIndex);
			
			if (!g_bBotFixed && !g_bOrbit && !(iRocketState & RocketState_Bouncing || iRocketState & RocketState_Dragging) 
				&& g_fOrbitAngleMin < fAngle < g_fOrbitAngleMax && fRocketPosition[2] >= fBotPosition[2] + 50.0)
			{
				g_iDeflectRadius = 0;
				g_bOrbit = true;

				if (TFDB_GetRocketMphSpeed(iIndex) < g_fOrbitMaxRocketSpeed)	// Had to use mph its a much smaller number to work with than hammer
				{
					g_iCriticalDefRadius = 40;
					//CPrintToChatAll("orbit");

					float forbTime = GetRandomFloat(g_fOrbitTimeMin, g_fOrbitTimeMax);
					CreateTimer(forbTime, Timer_ResetDistance);

					CreateTimer(0.1, Timer_StartOrb);

					CreateTimer(forbTime - 0.15, Timer_EndOrb);
				}
			}
			else	
			{
				g_iDeflectRadius = GetRandomInt(g_iDeflectRadiusMin, g_iDeflectRadiusMax);
			}

			if (!g_bBotFixed && g_bOrbit && fAngle < g_fAvoidRocketAngle)
				AvoidRocket(fBotPosition, fRocketPosition);

			g_fRandomAngle = ((g_iDeflectRadius + 1.0)/2.0) + 45.0;
		}

		if (GetVectorDistance(fBotPosition, fRocketPosition) <= g_iBotMoveDistance && GetEntProp(iRocket, Prop_Send, "m_iTeamNum") != GetClientTeam(g_iBot))
		{
			float fAngle[3], fBotRocket[3];
			MakeAngle(fRocketPosition, fBotPosition, fAngle);

			if ((GetVectorDistance(fBotPosition, fRocketPosition) <= g_iDeflectRadius && GetAngleToTarget(g_iBot, iRocket) <= g_fRandomAngle/2)
				|| GetVectorDistance(fBotPosition, fRocketPosition) <= g_iCriticalDefRadius)
			{
				TeleportEntity(g_iBot, NULL_VECTOR, fAngle, NULL_VECTOR);
				g_bAttack = true;
				g_bDeflectPause = false;

				if (!g_bChoiceAngle)
				{
					g_fGlobalAngle[0] = fAngle[0];
					g_fGlobalAngle[1] = fAngle[1];
					g_fGlobalAngle[2] = fAngle[2];
				}
			}
			else	// Orbit rocket
			{
				if (!g_bOrbit)
					g_bOrbit = true;

				MakeVectorFromPoints(fRocketPosition, fBotPosition, fBotRocket);

				fBotRocket[2] = 0.0;
				ScaleVector(fBotRocket, 9000.0);
				TeleportEntity(g_iBot, NULL_VECTOR, NULL_VECTOR, fBotRocket);
			}
		}
		else
		{
			float fAngle[3], fTargetPosition[3], fPlayerPosition[3], fNewPoint[3], fViewingAngleToRocket[3];
			fTargetPosition = GetTargetPosition(g_iBot);

			GetViewAnglesToTarget(g_iBot, fRocketPosition, fViewingAngleToRocket);

			if (g_iCurrentPlayer != -1 && g_bFlick && !g_bOrbit && GetRandomInt(-10, 10) == 2)
			{
				GetClientEyePosition(g_iCurrentPlayer, fPlayerPosition);
				fPlayerPosition[2] -= 20.0;

				GetViewAnglesToTarget(g_iBot, fPlayerPosition, fViewingAngleToRocket);
				//CPrintToChatAll("%.4f %.4f %.4f", fViewingAngleToRocket[0], fViewingAngleToRocket[1], fViewingAngleToRocket[2]);

				TeleportEntity(g_iBot, NULL_VECTOR, fViewingAngleToRocket, NULL_VECTOR);
			}

			if (!g_bFlick && !g_bTrackRocket)
				TeleportEntity(g_iBot, NULL_VECTOR, fViewingAngleToRocket, NULL_VECTOR);


			int iPlayer = EntRefToEntIndex(TFDB_GetRocketTarget(iIndex));
			if (IsValidClient(iPlayer, false, false))
				g_iCurrentPlayer = iPlayer;

			if (g_iCurrentPlayer != -1 && !g_bOrbit)
			{
				if (g_bBotFixed)	// fixed-position
				{
					MakeVectorFromPoints(fTargetPosition, fBotPosition, fNewPoint);
					NormalizeVector(fNewPoint, fNewPoint);

					GetClientEyePosition(g_iCurrentPlayer, fTargetPosition);
					MakeAngle(fTargetPosition, fBotPosition, fAngle);

					if (g_bDeflectPause && GetVectorDistance(fBotPosition, fTargetPosition) > 25.0) // We don't wanna move while performing a reflection/orbit
					{
						fNewPoint[2] = 0.0;
						ScaleVector(fNewPoint, -1000.0);
						TeleportEntity(g_iBot, NULL_VECTOR, NULL_VECTOR, fNewPoint);
					}
				}
				else	// player-mimic
				{
					// Here this might be confusing but the fTargetPosition is used for mimicing the player (position)
					GetClientEyePosition(g_iCurrentPlayer, fTargetPosition);
					MakeAngle(fTargetPosition, fBotPosition, fAngle);

					if (GetRandomInt(-20, 20) == 0)
					{
						g_fRandomPosition = RandomPosition();
					}

					SubtractVectors(fTargetPosition, g_fRandomPosition, fTargetPosition);

					NegateVector(fTargetPosition);
					MakeVectorFromPoints(fTargetPosition, fBotPosition, fNewPoint);
					NormalizeVector(fNewPoint, fNewPoint);

					if (g_bDeflectPause && GetVectorDistance(fBotPosition, fTargetPosition) > 150.0)
					{
						fNewPoint[2] = 0.0;
						ScaleVector(fNewPoint, -1500.0);
						TeleportEntity(g_iBot, NULL_VECTOR, NULL_VECTOR, fNewPoint);
					}
				}
			}

			if (g_bChoiceAngle)
			{
				g_bChoiceAngle = false;
				g_fGlobalAngle[0] = fAngle[0];
				g_fGlobalAngle[1] = fAngle[1];
				g_fGlobalAngle[2] = fAngle[2];
			}
		}
	}
}

int FindNextValidRocket(const int &iIndex)
{
	for (int i = iIndex + 1; i < MAX_ROCKETS; i++)
	{
		if (TFDB_IsValidRocket(i)) return i;
	}

	return -1;
}

void MakeAngle(const float fPos1[3], const float fPos2[3], float fOutput[3])
{
	float fBuffer[3];
	MakeVectorFromPoints(fPos1, fPos2, fBuffer);
	NormalizeVector(fBuffer, fBuffer);
	GetVectorAngles(fBuffer, fOutput);
	AngleFix(fOutput);
}

void AngleFix(float fAngle[3])
{
	fAngle[0] *= -1.0;

	if (fAngle[0] > 270)
		fAngle[0] -=360.0;

	if (fAngle[0] < -180.0)
		fAngle[0] += 360.0;

	fAngle[1] += 180.0;
}

float[] RandomPosition()
{
	float fPosition[3];
	fPosition[0] = GetRandomFloat(150.0, 600.0) * GetRandomFloat(-1.0, 1.0);
	fPosition[1] = GetRandomFloat(150.0, 600.0) * GetRandomFloat(-1.0, 1.0);
	fPosition[2] = 0.0;

	return fPosition;
}

void Flick()
{
	// So it seems like after doing some statistics "if" statements were more consistent in completion time ranging from ~0.087-0.107 in average it was ~0.1047
	// compared to "switch" which had a bigger deviation ranging ~0.078-0.116 in average it was ~0.1167 because of the more consistent time this configuration is used, this part of the code should not be touched.
	if (GetRandomInt(1, 5) == 5)
	{
		g_bChoiceAngle = true;
	}
	else
	{
		switch (GetRandomInt(1, 7)) //here the switch stayed for convenience
		{
			case 1:
			{
				g_fGlobalAngle[1] += GetRandomFloat(-40.0, 20.0);
			}
			case 2, 3, 4:
			{
				g_fGlobalAngle[0] += GetRandomFloat(g_fDragXMin, g_fDragXMax);
			}
			case 5, 6, 7:
			{
				g_fGlobalAngle[1] += GetRandomFloat(g_fDragYMin, g_fDragYMax);
			}
		}
	}

	if (g_fGlobalAngle[0] <= -90.0)		// Other type of angle fix for the two axis
	{
		g_fGlobalAngle[0] = -89.0;
	}
	else if (g_fGlobalAngle[0] >= 90.0)
	{
		g_fGlobalAngle[0] = 89.0;
	}

	if (g_fGlobalAngle[1] > 180.0)
	{
		g_fGlobalAngle[1] -= 360.0;
	}
	else if (g_fGlobalAngle[1] < -180.0)
	{
		g_fGlobalAngle[1] += 360.0;
	}

	TeleportEntity(g_iBot, NULL_VECTOR, g_fGlobalAngle, NULL_VECTOR);
}

void AvoidRocket(const float fBotPos[3], const float fRocketPos[3])
{
	float fBotRocket[3];
	MakeVectorFromPoints(fRocketPos, fBotPos, fBotRocket);

	if (fBotRocket[0] < 0 || fBotRocket[1] < 0)
	{
		g_fOrbitDegree *= -1.0;
	}

	float x = fBotRocket[0], y = fBotRocket[1]; fBotRocket[2] = 0.0;
	fBotRocket[0] = x * Cosine(DegToRad(g_fOrbitDegree)) - y * Sine(DegToRad(g_fOrbitDegree));
	fBotRocket[1] = x * Sine(DegToRad(g_fOrbitDegree)) + y * Cosine(DegToRad(g_fOrbitDegree));

	ScaleVector(fBotRocket, -15000.0); // Ik it's a big ass scale

	for	(int i = 0; i <= 4; i++)
	{
		TeleportEntity(g_iBot, NULL_VECTOR, NULL_VECTOR, fBotRocket);
	}
}

public Action Timer_ResetState(Handle hTimer)
{
	g_bDeflectPause = true;
	g_bChoiceAngle = false;

	return Plugin_Stop;
}

public Action Timer_ResetDistance(Handle hTimer)
{
	g_iDeflectRadius = 285;
	g_iCriticalDefRadius = 100;

	return Plugin_Stop;
}

public Action Timer_StartOrb(Handle hTimer)
{
	g_bTrackRocket = false;

	return Plugin_Stop;
}

public Action Timer_EndOrb(Handle hTimer)
{
	g_bTrackRocket = true;

	return Plugin_Stop;
}


// ---------------- [Enable / Disable] ---------------------
void EnableMode()
{
	CleanBots();	// Kicking any other bot that might be present

	ServerCommand("sm_cvar tf_bot_quota_mode normal"); // Setting up the server for the mode
	ServerCommand("sm_cvar tf_bot_quota 0");
	ServerCommand("sm_cvar tf_bot_pyro_shove_away_range 0");
	ServerCommand("mp_autoteambalance 0");

	ServerCommand("tf_bot_add 1 Pyro %s easy \"%s\"", g_CvarBotTeam.IntValue == 2 ? "red" : "blue", g_strBotName);	// Creating the bot
	ServerCommand("tf_bot_difficulty 0");
	ServerCommand("tf_bot_keep_class_after_death 1");
	ServerCommand("tf_bot_taunt_victim_chance 0");
	ServerCommand("tf_bot_join_after_player 0");

	ChangeClientsTeam();	// Changing already joined players teams
	
	g_bEnable = true;

	CPrintToChatAll("%t", "PVB_Enable");
}

void DisableMode()
{
	// Restore everything to its default value
	ServerCommand("sm_cvar tf_bot_pyro_shove_away_range 250");

	g_iBot = -1;
	g_iWeapon = -1;
	g_iCurrentPlayer = -1;
	g_bEnable = false;
	g_bBotFixed = false;

	CleanBots();	// Kick all bots

	CPrintToChatAll("%t", "PVB_Disable");
}

// ------------------------- [Commands] ------------------------------
public Action PVB_ReloadCfg(int iClient, int iArgs)
{
	if (!g_CvarPVBenable.BoolValue || !TFDB_IsDodgeballEnabled())
	{
		CPrintToChat(iClient, "%t", "PVB_Mode_Disabled");

		return Plugin_Handled;
	}

	ParseConfig();

	CReplyToCommand(iClient, "Bot config has been reloaded!");

	return Plugin_Handled;
}

public Action PVB_Cmd(int iClient, int iArgs) 
{
	if (!g_CvarPVBenable.BoolValue || !TFDB_IsDodgeballEnabled())
	{
		CPrintToChat(iClient, "%t", "PVB_Mode_Disabled");

		return Plugin_Handled;
	}

	if (g_bEnable)
		DisableMode();
	else
		EnableMode();

	return Plugin_Handled;
}

public Action VotePvB_Cmd(int iClient, int iArgs)
{
	if (!g_CvarPVBenable.BoolValue || !TFDB_IsDodgeballEnabled())
	{
		CPrintToChat(iClient, "%t", "PVB_Mode_Disabled");

		return Plugin_Handled;
	}

	if (g_fPVBVoteTime != 0.0 && g_fPVBVoteTime + g_CvarVoteCooldown.FloatValue > GetGameTime() && GetRealClientCount() > 1)
	{
		CPrintToChat(iClient, "%t", "PVB_Vote_Cooldown", g_fPVBVoteTime + g_CvarVoteCooldown.FloatValue - GetGameTime());

		return Plugin_Handled;
	}

	if (IsVoteInProgress())
	{
		CPrintToChat(iClient, "%t", "Dodgeball_FFAVote_Conflict");
		
		return Plugin_Handled;
	}

	Menu hMenu = new Menu(VoteMenuHandler);
	hMenu.VoteResultCallback = VotePVBResultCallBack;
	
	hMenu.SetTitle("%s Player vs. Bot mode?", g_bEnable ? "Disable" : "Enable");
	hMenu.AddItem("0", "Yes");
	hMenu.AddItem("1", "No");
	
	int iTotal;
	int[] iClients = new int[MaxClients];

	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!IsValidClient(i)) continue;

		iClients[iTotal++] = i;
	}
	
	hMenu.DisplayVote(iClients, iTotal, 10);

	g_fPVBVoteTime = GetGameTime();

	return Plugin_Handled;
}

// ------------- [Votehandlers] --------------------
public int VoteMenuHandler(Menu hMenu, MenuAction iMenuActions, int iParam1, int iParam2) 
{
	if (iMenuActions == MenuAction_End) delete hMenu;
	
	return 0;
}

public void VotePVBResultCallBack(Menu hMenu, int iNumVotes, int iNumClients, const int[][] iClientInfo, int iNumItems, const int[][] iItemInfo) 
{
	int iWinnerIndex = 0;
	
	if (iNumItems > 1 && (iItemInfo[0][VOTEINFO_ITEM_VOTES] == iItemInfo[1][VOTEINFO_ITEM_VOTES]))
	{
		iWinnerIndex = GetRandomInt(0, 1);
	}
	
	char strWinner[8];
	hMenu.GetItem(iItemInfo[iWinnerIndex][VOTEINFO_ITEM_INDEX], strWinner, sizeof(strWinner));

	if (StrEqual(strWinner, "0"))
	{
		if (g_bEnable)
			DisableMode();
		else
			EnableMode();
	}
	else
	{
		CPrintToChatAll("%t", "PVB_Vote_Failed");
	}
}

// ------------- [Parse Config] --------------------
void ParseConfig()
{
	ResetTargetPositions();

	char strPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/dodgeball_bot.cfg");

	KeyValues kv = new KeyValues("DodgeballBot");

	if (!kv.ImportFromFile(strPath)) SetFailState("No Dodgeball bot config found in path '%s'", strPath);

	if (!kv.GotoFirstSubKey(false))
	{
		LogError("Invalid DodgeballBot Config found in path '%s'. Taking the rocket spawn locations", strPath);
		delete kv;
		return;
	}

	do
	{
		char strConfigSection[64]; kv.GetSectionName(strConfigSection, sizeof(strConfigSection));

		if (StrEqual(strConfigSection, "general")) 		ParseGeneral(kv);
		else if (StrEqual(strConfigSection, "maps")) 	ParseMaps(kv);
	}
	while(kv.GotoNextKey());

	delete kv;

	if (!(GetVectorDistance(g_fTargetPositions[0], NULL_VECTOR) <= 1.0 || GetVectorDistance(g_fTargetPositions[1], NULL_VECTOR) <= 1.0))
	{
		g_bBotFixed = true;
	}
}

void ParseGeneral(KeyValues kv)
{
	kv.GetString("name", g_strBotName, sizeof(g_strBotName));

	g_iDeflectRadiusMin = kv.GetNum("deflect radius min");
	g_iDeflectRadiusMax = kv.GetNum("deflect radius max");

	g_fDragXMin	= kv.GetFloat("x-axis drag min");
	g_fDragXMax	= kv.GetFloat("x-axis drag max");

	g_fDragYMin = kv.GetFloat("y-axis drag min");
	g_fDragYMax = kv.GetFloat("y-axis drag max");

	g_fOrbitTimeMin = kv.GetFloat("orbit time min");
	g_fOrbitTimeMax = kv.GetFloat("orbit time max");

	g_fOrbitAngleMin = kv.GetFloat("orbit angle min");
	g_fOrbitAngleMax = kv.GetFloat("orbit angle max");

	g_fOrbitDegree = kv.GetFloat("orbit angle");

	g_fAvoidRocketAngle = kv.GetFloat("avoid rocket angle");

	g_fOrbitMaxRocketSpeed = kv.GetFloat("orbit max speed");
}

void ParseMaps(KeyValues kv)
{
	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

	kv.GotoFirstSubKey();
	do
	{
		char sConfigSectionName[128];
		if (!kv.GetSectionName(sConfigSectionName, sizeof(sConfigSectionName)) || strcmp(sConfigSectionName, sMapName) != 0)
		{
			continue;
		}

		if (kv.JumpToKey("red"))
		{
			g_fTargetPositions[0][0] = kv.GetFloat("Coord_X");
			g_fTargetPositions[0][1] = kv.GetFloat("Coord_Y");
			g_fTargetPositions[0][2] = kv.GetFloat("Coord_Z");

			kv.GoBack();
		}

		if (kv.JumpToKey("blue"))
		{
			g_fTargetPositions[1][0] = kv.GetFloat("Coord_X");
			g_fTargetPositions[1][1] = kv.GetFloat("Coord_Y");
			g_fTargetPositions[1][2] = kv.GetFloat("Coord_Z");
		}
	}
	while (kv.GotoNextKey(false));
}

// ------------- [Stocks] --------------------
float[] GetTargetPosition(int &iClient)
{
	int iTeam = GetClientTeam(iClient);

	if (iTeam == view_as<int>(TFTeam_Red))
	{
		return g_fTargetPositions[0];
	}
	else
	{
		return g_fTargetPositions[1];
	}
}

void GetViewAnglesToTarget(int &iClient, const float fTargetPosition[3], float fAngleOutput[3])
{ 
	float fClientEyes[3], fPositionalVector[3];

	GetClientEyePosition(iClient, fClientEyes);
	MakeVectorFromPoints(fTargetPosition, fClientEyes, fPositionalVector);
	GetVectorAngles(fPositionalVector, fAngleOutput);

	if (fAngleOutput[0] >= 270)
	{ 
		fAngleOutput[0] -= 270;
		fAngleOutput[0] -= 90;
	}
	else if (fAngleOutput[0] <= 90)
	{ 
		fAngleOutput[0] *= -1;
	}

	fAngleOutput[1] -= 180;
}

void ResetTargetPositions()
{
	for (int i = 0; i < 2; i++)
	{
		g_fTargetPositions[i] = NULL_VECTOR;
	}
}

float GetAngleToTarget(int &iClient, int &iTarget)
{
	float fClientPosition[3], fTargetPosition[3], fAngle[3], fTargetVector[3], fResultAngle;

	GetClientEyeAngles(iClient, fAngle);
	fAngle[0] = fAngle[2] = 0.0;

	GetAngleVectors(fAngle, fAngle, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(fAngle, fAngle);

	GetClientAbsOrigin(iClient, fClientPosition);

	GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fTargetPosition);
	fClientPosition[2] = fTargetPosition[2] = 0.0;

	MakeVectorFromPoints(fClientPosition, fTargetPosition, fTargetVector);
	NormalizeVector(fTargetVector, fTargetVector);

	fResultAngle = RadToDeg(ArcCosine(GetVectorDotProduct(fTargetVector, fAngle)));

	return fResultAngle;
}

int GetRealClientCount(bool bInGameOnly = true)
{
	int iCount = 0;

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (((bInGameOnly) ? IsClientInGame(iClient) : IsClientConnected(iClient)) && !IsFakeClient(iClient) && !IsClientReplay(iClient) && !IsClientSourceTV(iClient))
			iCount++;
	}

	return iCount;
}

bool IsValidClient(int &iClient, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= iClient <= MaxClients) || !IsClientInGame(iClient) || (IsFakeClient(iClient) && !bAllowBots)
		|| IsClientSourceTV(iClient) || IsClientReplay(iClient) || (!bAllowDead && !IsPlayerAlive(iClient)))
	{
		return false;
	}

	return true;
}

void ChangeClientsTeam()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient) && GetClientTeam(iClient) == g_CvarBotTeam.IntValue)
		{
			ChangeClientTeam(iClient, AnalogueTeam(g_CvarBotTeam.IntValue));
		}
	}
}

void CleanBots()
{
	ServerCommand("tf_bot_kick all");
}