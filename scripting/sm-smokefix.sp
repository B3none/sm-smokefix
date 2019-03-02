#include <sourcemod>
#include <sdktools>
#include <sdkhooks> 

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[SM] Smoke Fix",
	author = "B3none",
	description = "Fixes being able to see players on the radar through smoke.",
	version = "2.0.0",
	url = "https://github.com/b3none/sm-smokefix"
};

#define MODEL "models/rxg/smokevol.mdl"
#define DURATION 18.0

public void OnPluginStart() 
{
	HookEvent("smokegrenade_detonate", OnSmokeDetonated);
}

public void OnMapStart() 
{
	PrecacheModel(MODEL);
}

public Action OnSmokeDetonated(Handle event, const char[] name, bool dontBroadcast) 
{
	float pos[3];
	pos[0] = GetEventFloat(event, "x");
	pos[1] = GetEventFloat(event, "y");
	pos[2] = GetEventFloat(event, "z");
	pos[2] += 40.0;
	int ent = CreateEntityByName("prop_physics_multiplayer");
	SetEntityModel(ent, MODEL);	
	
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	AcceptEntityInput(ent, "DisableMotion");
	 
	SDKHook(ent, SDKHook_ShouldCollide, OnCollision); 
	SetEdictFlags(ent, (GetEdictFlags(ent)&(~FL_EDICT_ALWAYS))|FL_EDICT_DONTSEND); // allow settransmit hooks
	
	CreateTimer(DURATION, KillVolume, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
}

public bool OnCollision(int entity, int collisiongroup, int contentsmask, bool originalResult) 
{
	// grenades and bullets should not clip
	// some things...like chickens... will still not be able to pass through the volume, but hey blame valve for this shit
	return !(collisiongroup == 13 || collisiongroup == 0);
}

public Action KillVolume(Handle timer, any ref)
{
	int ent = EntRefToEntIndex(ref);
	if (ent == INVALID_ENT_REFERENCE)
	{
		return  Plugin_Handled;	
	}
	
	if (IsValidEntity(ent)) 
	{
		AcceptEntityInput(ent, "Kill");
	}
	
	return Plugin_Handled;
}
