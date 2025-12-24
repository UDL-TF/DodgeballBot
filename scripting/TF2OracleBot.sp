#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#include <multicolors>
#include <tfdb>

#define PLUGIN_NAME        "[TFDB] Oracle Bot"
#define PLUGIN_AUTHOR      "Nebula"
#define PLUGIN_DESCIPTION  "A practice bot for dodgeball."
#define PLUGIN_VERSION     "2.1.0"
#define PLUGIN_URL         "-"

#define AnalogueTeam(%1) (%1^1)

bool g_bEnable = false;

int iBot = -1;
int g_iWeapon = -1;
int g_iDeflectRadius = 750;
int g_iCriticalDefRadius = 100;
int g_iBotMoveDistance = 400;

float g_fRandomAngle = 180.0;
float g_fMinDragTime = 0.0;
float g_fGlobalAngle[3];
float g_fTargetPositions[2][3];

bool g_bChoiceAngle 	= false;
bool g_bAttack 			= false;
bool g_bDeflectPause 	= true;
bool g_bOrbit			= false;

float g_fPVBVoteTime = 0.0;

ConVar g_CvarPVBenable;
ConVar g_CvarVoteCooldown;
ConVar g_CvarBotTeam;

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
	RegConsoleCmd("sm_votepvb", VotePvB_Cmd);

	g_CvarPVBenable = CreateConVar("tfdb_pvb_enable", "1", "Enable/disable player vs bot mode.", _ ,true, 0.0, true, 1.0);
	g_CvarVoteCooldown = CreateConVar("tfdb_pvb_vote_cooldown", "120", "Voting timeout for PVB.", _, true, 0.0);
	g_CvarBotTeam = CreateConVar("tfdb_bot_team", "2", "The default team for the bot, 2 - Red, 3 - Blu", _, true, 2.0, true, 3.0);

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("object_deflected", OnObjectDeflected);

	LoadTranslations("tfdb.phrases.txt");

	g_fPVBVoteTime = 0.0;
}

public void OnConfigsExecuted()
{
	CheckForMapTargetPosition();
}

public void OnMapStart()
{
	g_fPVBVoteTime = 0.0;
}

public void OnMapEnd()
{
	if (g_bEnable) DisableMode();
}

public void OnClientDisconnect(int iClient)
{
	if (iClient == iBot || GetRealClientCount() == 0)
	{
		DisableMode();
	}
}

public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!g_bEnable)
	{
		DestroyBot();
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
			iBot = iClient;

			ChangeClientTeam(iClient, g_CvarBotTeam.IntValue);
			SetEntityGravity(iClient, 400.0);
			SetEntProp(iBot, Prop_Data, "m_takedamage", 1, 1);
			g_iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		}
	}

	return Plugin_Continue;
}

public void OnObjectDeflected(Event hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (!g_bEnable) return;

	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (iClient != iBot) return;

	//CPrintToChatAll("1. %.4f", GetEngineTime());
	CreateTimer(FloatAbs(g_fMinDragTime - 0.1), Timer_Flick); // 0.1 is a correction number for the completion of the code
}

// ------------------ [Core function] -----------------------------
public void OnGameFrame()
{
	if (!g_bEnable && iBot == -1) return;

	float fBotPosition[3], fRocketPosition[3];
	float a[3], b[3];
	g_bAttack = false;

	int iIndex = -1;
	while((iIndex = FindNextValidRocket(iIndex)) != -1)
	{
		// I used the same method to spin through rockets as in the dodgeball plugin
		g_fMinDragTime = TFDB_GetRocketClassDragTimeMin(TFDB_GetRocketClass(iIndex));
		int iRocket = TFDB_GetRocketEntity(iIndex);

		GetClientEyePosition(iBot, fBotPosition);
		GetEntPropVector(iRocket, Prop_Send, "m_vecOrigin", fRocketPosition);

		if (GetVectorDistance(fBotPosition, fRocketPosition) <= g_iBotMoveDistance && GetEntProp(iRocket, Prop_Send, "m_iTeamNum") != g_CvarBotTeam.IntValue)
		{
			float fAngle[3], fBotRocket[3];
			MakeAngle(fRocketPosition, fBotPosition, fAngle);

			NormalizeVector(fBotPosition, a);
			NormalizeVector(fRocketPosition, b);
			a[2] = b[2] = 0.0;

			if ((GetVectorDistance(fBotPosition, fRocketPosition) <= g_iDeflectRadius && GetAngleToTarget(iBot, iRocket) <= g_fRandomAngle/2)
				|| GetVectorDistance(fBotPosition, fRocketPosition) <= g_iCriticalDefRadius)
			{
				TeleportEntity(iBot, NULL_VECTOR, fAngle, NULL_VECTOR);
				g_bAttack = true;
				g_bDeflectPause = false;

				if (!g_bChoiceAngle)
				{
					g_fGlobalAngle[0] = fAngle[0];
					g_fGlobalAngle[1] = fAngle[1];
					g_fGlobalAngle[2] = fAngle[2];
				}
			}
			else
			{
				MakeVectorFromPoints(fRocketPosition, fBotPosition, fBotRocket);
				if (g_bOrbit)
				{
					float radian = DegToRad(110.0);
					//CPrintToChatAll("%.4f", radian);

					if (fBotRocket[0] < 0 || fBotRocket[1] < 0)
					{
						radian *= -1.0;
					}
					//CPrintToChatAll("modified: %.4f", radian);

					float x = fBotRocket[0], y = fBotRocket[1]; //CPrintToChatAll("x: %.4f	y: %.4f", x, y);
					fBotRocket[0] = x * Cosine(radian) - y * Sine(radian);
					fBotRocket[1] = x * Sine(radian) + y * Cosine(radian);
					//CPrintToChatAll("modified x: %.4f	y: %.4f", fBotRocket[0], fBotRocket[1]);

					ScaleVector(fBotRocket, -6000.0);
				}

				fBotRocket[2] = 0.0;
				if (!g_bOrbit) ScaleVector(fBotRocket, 6000.0);
				TeleportEntity(iBot, NULL_VECTOR, NULL_VECTOR, fBotRocket);
			}
		}
		else
		{
			float fAngle[3], fTargetPosition[3], fNewPoint[3], fViewingAngleToRocket[3];
			fTargetPosition = GetTargetPosition(iBot);

			int iPlayer = EntRefToEntIndex(TFDB_GetRocketTarget(iIndex));

			if (!IsValidClient(iPlayer, false, false)) return;

			if (!(GetVectorDistance(fTargetPosition, NULL_VECTOR) <= 1.0)) // Here it's used to store the target position on the map
			{
				MakeVectorFromPoints(fTargetPosition, fBotPosition, fNewPoint);
				NormalizeVector(fNewPoint, fNewPoint);

				GetClientEyePosition(iPlayer, fTargetPosition);
				MakeAngle(fTargetPosition, fBotPosition, fAngle);

				if (g_bDeflectPause && GetVectorDistance(fBotPosition, fTargetPosition) > 25.0) // We don't wanna move while performing a reflection/orbit
				{
					GetViewAnglesToTarget(iBot, fRocketPosition, fViewingAngleToRocket);

					fNewPoint[2] = 0.0;
					ScaleVector(fNewPoint, -1000.0);
					TeleportEntity(iBot, NULL_VECTOR, fViewingAngleToRocket, fNewPoint);
				}
			}
			else
			{
				// Here this might be confusing but the fTargetPosition is used for mimicing the player (position)
				GetClientEyePosition(iPlayer, fTargetPosition);
				MakeAngle(fTargetPosition, fBotPosition, fAngle);

				NegateVector(fTargetPosition);
				MakeVectorFromPoints(fTargetPosition, fBotPosition, fNewPoint);
				NormalizeVector(fNewPoint, fNewPoint);

				if (g_bDeflectPause && GetVectorDistance(fBotPosition, fTargetPosition) > 25.0)
				{
					GetViewAnglesToTarget(iBot, fRocketPosition, fViewingAngleToRocket);

					fNewPoint[2] = 0.0;
					ScaleVector(fNewPoint, -1000.0);
					TeleportEntity(iBot, NULL_VECTOR, fViewingAngleToRocket, fNewPoint);
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

		if (!g_bDeflectPause)
		{
			CreateTimer(0.1, Timer_ResetState); // I don't know why we have to wait 0.1 but ig it works

			RocketState State = TFDB_GetRocketState(iIndex); //GetVectorDotProduct(a, b) > Cosine(DegToRad(30.0))
			if (GetRandomInt(1, 3) == 3 && GetAngleToTarget(iBot, iRocket) > 30.0)
			{
				g_iDeflectRadius = 0;
				g_iCriticalDefRadius = 40;
				g_bOrbit = true;
				CPrintToChatAll("orbit");
				CreateTimer(2.5, Timer_ResetDistance);
			}
			else	
			{
				g_iDeflectRadius = GetRandomInt(200, 250);
			}

			g_fRandomAngle = ((g_iDeflectRadius + 1.0)/2.0) + 45.0;
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

void MakeAngle(const float fPos1[3], const float fPos2[3], float fAngle[3])
{
	float fBuffer[3];
	MakeVectorFromPoints(fPos1, fPos2, fBuffer);
	NormalizeVector(fBuffer, fBuffer);
	GetVectorAngles(fBuffer, fAngle);
	AngleFix(fAngle);
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
	g_bOrbit = false;

	return Plugin_Stop;
}

public Action Timer_Flick(Handle hTimer)
{
	// So it seems like after doing some statistics "if" statements were more consistent in completion time ranging from ~0.087-0.107 in average it was ~0.1047
	// compared to "switch" which had a bigger deviation ranging ~0.078-0.116 in average it was ~0.1167 because of the more consistent time this configuration is used, this part of the code should not be touched.
	if (GetRandomInt(1, 5) == 5)
	{
		g_bChoiceAngle = true;
	}
	else
	{
		switch (GetRandomInt(1, 10)) //here the switch stayed for convenience
		{
			case 1, 2, 3:
			{
				g_fGlobalAngle[0] += GetRandomFloat(-10.0, 10.0);
			}
			case 4, 5, 6:
			{
				g_fGlobalAngle[1] += GetRandomFloat(-15.0, 15.0);
			}
			case 7, 8:
			{
				g_fGlobalAngle[0] += GetRandomFloat(-90.0, 90.0);
			}
			case 9, 10:
			{
				g_fGlobalAngle[1] += GetRandomFloat(-90.0, 90.0);
			}
		}
	}

	if (g_fGlobalAngle[0] <= -90.0)
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

	TeleportEntity(iBot, NULL_VECTOR, g_fGlobalAngle, NULL_VECTOR);
	//CPrintToChatAll("2. %.4f", GetEngineTime());

	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (g_bAttack && iClient == iBot && g_iWeapon != -1)
	{
		SetEntPropFloat(g_iWeapon, Prop_Send, "m_flNextSecondaryAttack", 0.0);

		iButtons |= IN_ATTACK2;
	}

	return Plugin_Continue;
}

// ---------------- [Enable / Disable] ---------------------
void EnableMode()
{
	DestroyBot();
	ServerCommand("sm_cvar tf_bot_quota_mode normal");
	ServerCommand("sm_cvar tf_bot_quota 0");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("tf_bot_add 1 Pyro red easy \"Oracle BOT\"");
	ServerCommand("tf_bot_difficulty 0");
	ServerCommand("tf_bot_keep_class_after_death 1");
	ServerCommand("tf_bot_taunt_victim_chance 0");
	ServerCommand("tf_bot_join_after_player 0");

	ChangeClientsTeam();
	
	g_bEnable = true;

	CPrintToChatAll("%t", "PVB_Enable");
}

void DisableMode()
{
	iBot = -1;
	g_iWeapon = -1;
	g_bEnable = false;

	DestroyBot();

	CPrintToChatAll("%t", "PVB_Disable");
}

// ------------------------- [Commands] ------------------------------
public Action PVB_Cmd(int iClient, int iArgs) 
{
	if (!g_CvarPVBenable.BoolValue || !TFDB_IsDodgeballEnabled())
	{
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
		return Plugin_Handled;
	}

	if (!g_fPVBVoteTime && g_fPVBVoteTime + g_CvarVoteCooldown.FloatValue > GetGameTime() && GetRealClientCount() > 1)
	{
		CPrintToChat(iClient, "%t", "PVB_Vote_Cooldown", g_fPVBVoteTime + g_CvarVoteCooldown.FloatValue - GetGameTime());

		return Plugin_Handled;
	}

	if (IsVoteInProgress())
	{
		CPrintToChat(iClient, "%t", "Dodgeball_Vote_Conflict");
		
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
		if(!IsValidClient(i)) continue;

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
		CPrintToChatAll("%t", "Dodgeball_PVBVote_Failed");
	}
}

void CheckForMapTargetPosition()
{
	ResetTargetPositions();

	char cfg[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, cfg, sizeof(cfg), "configs/dodgeball/dodgeball-bot-targets.cfg");

	KeyValues kv = new KeyValues("DodgeballBot");
	if (!kv.ImportFromFile(cfg))
	{
		LogError("No DodgeballBot Config found in path '%s'. Taking the rocket spawn locations", cfg);
		delete kv;
		return;
	}

	if (!kv.GotoFirstSubKey(false))
	{
		LogError("Invalid DodgeballBot Config found in path '%s'. Taking the rocket spawn locations", cfg);
		delete kv;
		return;
	}

	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	// PrintToChatAll(sMapName);

	do
	{
		char sConfigSectionName[128];
		if (!kv.GetSectionName(sConfigSectionName, sizeof(sConfigSectionName)) || strcmp(sConfigSectionName, sMapName) != 0)
		{
			continue;
		}

		if (kv.JumpToKey("red"))
		{
			char sSectionName[128];
			kv.GetSectionName(sSectionName, sizeof(sSectionName));
			// PrintToChatAll(sSectionName);
			g_fTargetPositions[0][0] = kv.GetFloat("Coord_X");
			g_fTargetPositions[0][1] = kv.GetFloat("Coord_Y");
			g_fTargetPositions[0][2] = kv.GetFloat("Coord_Z");
			// PrintToChatAll("Target 1: %f %f %f", g_fTargetPositions[0][0], g_fTargetPositions[0][1], g_fTargetPositions[0][2]);
			kv.GoBack();
		}
		if (kv.JumpToKey("blue"))
		{
			char sSectionName[128];
			kv.GetSectionName(sSectionName, sizeof(sSectionName));
			// PrintToChatAll(sSectionName);
			g_fTargetPositions[1][0] = kv.GetFloat("Coord_X");
			g_fTargetPositions[1][1] = kv.GetFloat("Coord_Y");
			g_fTargetPositions[1][2] = kv.GetFloat("Coord_Z");
			// PrintToChatAll("Target 2: %f %f %f", g_fTargetPositions[1][0], g_fTargetPositions[1][1], g_fTargetPositions[1][2]);
		}
	}
	while (kv.GotoNextKey(false));

	delete kv;
}

float[] GetTargetPosition(int iClient)
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

void GetViewAnglesToTarget(int iClient, const float fTargetPosition[3], float fAngleOutput[3])
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

int GetRealClientCount()
{
	int iCount = 0;

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{	
		if (IsValidClient(iClient)) iCount++;
	}

	return iCount;
}

bool IsValidClient(int iClient, bool bAllowBots = false, bool bAllowDead = true)
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

void DestroyBot()
{	
	ServerCommand("tf_bot_kick all");
}
