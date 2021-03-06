/*  CS:GO Weapons&Knives SourceMod Plugin
 *
 *  Copyright (C) 2017 Kağan 'kgns' Üstüngel
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

public int WeaponsMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				int index = g_iIndex[client];
				
				char skinIdStr[32];
				menu.GetItem(selection, skinIdStr, sizeof(skinIdStr));
				int skinId = StringToInt(skinIdStr);
				
				g_iSkins[client][index] = skinId;
				char updateFields[128];
				char weaponName[32];
				RemoveWeaponPrefix(g_WeaponClasses[index], weaponName, sizeof(weaponName));
				Format(updateFields, sizeof(updateFields), "%s = %d", weaponName, skinId);
				UpdatePlayerData(client, updateFields);
				
				RefreshWeapon(client, index);
				
				menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			}
		}
		case MenuAction_DisplayItem:
		{
			if(IsClientInGame(client))
			{
				char info[32];
				char display[64];
				menu.GetItem(selection, info, sizeof(info));
				
				if (StrEqual(info, "0"))
				{
					Format(display, sizeof(display), "%T", "DefaultSkin", client);
					return RedrawMenuItem(display);
				}
				else if (StrEqual(info, "-1"))
				{
					Format(display, sizeof(display), "%T", "RandomSkin", client);
					return RedrawMenuItem(display);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if (IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateWeaponMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	return 0;
}

public int WeaponMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "skin"))
				{
					menuWeapons[g_iClientLanguage[client]][g_iIndex[client]].Display(client, MENU_TIME_FOREVER);
				}
				else if(StrEqual(buffer, "float"))
				{
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else if(StrEqual(buffer, "stattrak"))
				{
					g_iStatTrak[client][g_iIndex[client]] = 1 - g_iStatTrak[client][g_iIndex[client]];
					char updateFields[50];
					char weaponName[32];
					RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
					Format(updateFields, sizeof(updateFields), "%s_trak = %d", weaponName, g_iStatTrak[client][g_iIndex[client]]);
					UpdatePlayerData(client, updateFields);
					
					RefreshWeapon(client, g_iIndex[client]);
					
					CreateTimer(1.0, StatTrakMenuTimer, client);
				}
				else if(StrEqual(buffer, "nametag"))
				{
					CreateNameTagMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action StatTrakMenuTimer(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		CreateWeaponMenu(client).Display(client, MENU_TIME_FOREVER);
	}
}

Menu CreateFloatMenu(int client)
{
	char buffer[20];
	Menu menu = new Menu(FloatMenuHandler);
	
	float fValue = g_fFloatValue[client][g_iIndex[client]];
	fValue = fValue * 100.0;
	int wear = 100 - RoundFloat(fValue);
	
	menu.SetTitle("%T%d%%", "SetFloat", client, wear);
	
	Format(buffer, sizeof(buffer), "%T", "Increase", client, g_iFloatIncrementPercentage);
	menu.AddItem("increase", buffer, wear == 100 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%T", "Decrease", client, g_iFloatIncrementPercentage);
	menu.AddItem("decrease", buffer, wear == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int FloatMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "increase"))
				{
					g_fFloatValue[client][g_iIndex[client]] = g_fFloatValue[client][g_iIndex[client]] - g_fFloatIncrementSize;
					if(g_fFloatValue[client][g_iIndex[client]] < 0.0)
					{
						g_fFloatValue[client][g_iIndex[client]] = 0.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(2.0, FloatTimer, pack);
					pack.WriteCell(client);
					pack.WriteCell(g_iIndex[client]);
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else if(StrEqual(buffer, "decrease"))
				{
					g_fFloatValue[client][g_iIndex[client]] = g_fFloatValue[client][g_iIndex[client]] + g_fFloatIncrementSize;
					if(g_fFloatValue[client][g_iIndex[client]] > 1.0)
					{
						g_fFloatValue[client][g_iIndex[client]] = 1.0;
					}
					if(g_FloatTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_FloatTimer[client]);
						g_FloatTimer[client] = INVALID_HANDLE;
					}
					DataPack pack;
					g_FloatTimer[client] = CreateDataTimer(1.0, FloatTimer, pack);
					pack.WriteCell(client);
					pack.WriteCell(g_iIndex[client]);
					CreateFloatMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateWeaponMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action FloatTimer(Handle timer, Handle pack)
{

	ResetPack(pack);
	int clientIndex = ReadPackCell(pack);
	int index = ReadPackCell(pack);
	
	if(IsClientInGame(clientIndex))
	{
		char updateFields[30];
		char weaponName[32];
		RemoveWeaponPrefix(g_WeaponClasses[index], weaponName, sizeof(weaponName));
		Format(updateFields, sizeof(updateFields), "%s_float = %.2f", weaponName, g_fFloatValue[clientIndex][g_iIndex[clientIndex]]);
		UpdatePlayerData(clientIndex, updateFields);
		
		RefreshWeapon(clientIndex, index);
		
		g_FloatTimer[clientIndex] = INVALID_HANDLE;
	}
}

Menu CreateNameTagMenu(int client)
{
	Menu menu = new Menu(NameTagMenuHandler);
	menu.SetTitle("%T", "NameTagInfo", client);
	
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", "NameTagColor", client);
	menu.AddItem("color", buffer, strlen(g_NameTag[client][g_iIndex[client]]) > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	Format(buffer, sizeof(buffer), "%T", "DeleteNameTag", client);
	menu.AddItem("delete", buffer, strlen(g_NameTag[client][g_iIndex[client]]) > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int NameTagMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				if(StrEqual(buffer, "color"))
				{
					CreateColorsMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else if(StrEqual(buffer, "delete"))
				{
					g_NameTag[client][g_iIndex[client]] = "";
					
					char updateFields[30];
					char weaponName[32];
					RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
					Format(updateFields, sizeof(updateFields), "%s_tag = ''", weaponName);
					UpdatePlayerData(client, updateFields);
					
					RefreshWeapon(client, g_iIndex[client]);
					
					CreateWeaponMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateWeaponMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

Menu CreateColorsMenu(int client)
{
	Menu menu = new Menu(ColorsMenuHandler);
	menu.SetTitle("%T", "ChooseColor", client);
	
	char buffer[128];
	
	Format(buffer, sizeof(buffer), "%T", "DefaultColor", client);
	menu.AddItem("default", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Black", client);
	menu.AddItem("000000", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Grey", client);
	menu.AddItem("555555", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Red", client);
	menu.AddItem("FF0000", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Green", client);
	menu.AddItem("00FF00", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "Blue", client);
	menu.AddItem("0000AA", buffer);
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int ColorsMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char buffer[30];
				menu.GetItem(selection, buffer, sizeof(buffer));
				
				char stripped[128];
				char escaped[257];
				char colored[128];
				char updateFields[300];
				StripHtml(g_NameTag[client][g_iIndex[client]], stripped, sizeof(stripped));
				if (StrEqual(buffer, "default"))
				{
					g_NameTag[client][g_iIndex[client]] = stripped;
					
					db.Escape(stripped, escaped, sizeof(escaped));
				}
				else
				{
					Format(colored, sizeof(colored), "<font color='#%s'>%s</font>", buffer, stripped);
					g_NameTag[client][g_iIndex[client]] = colored;
					
					db.Escape(colored, escaped, sizeof(escaped));
				}
				
				char weaponName[32];
				RemoveWeaponPrefix(g_WeaponClasses[g_iIndex[client]], weaponName, sizeof(weaponName));
				Format(updateFields, sizeof(updateFields), "%s_tag = '%s'", weaponName, escaped);
				UpdatePlayerData(client, updateFields);
				
				RefreshWeapon(client, g_iIndex[client]);
				
				CreateTimer(1.0, NameTagColorsMenuTimer, client);
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateNameTagMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action NameTagColorsMenuTimer(Handle timer, int client)
{
	if(IsClientInGame(client))
	{
		CreateColorsMenu(client).Display(client, MENU_TIME_FOREVER);
	}
}

Menu CreateAllWeaponsMenu(int client)
{
	Menu menu = new Menu(AllWeaponsMenuHandler);
	menu.SetTitle("%T", "AllWeaponsMenuTitle", client);
	
	char name[32];
	for (int i = 0; i < sizeof(g_WeaponClasses); i++)
	{
		Format(name, sizeof(name), "%T", g_WeaponClasses[i], client);
		menu.AddItem(g_WeaponClasses[i], name);
	}
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int AllWeaponsMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char class[30];
				menu.GetItem(selection, class, sizeof(class));
				
				g_smWeaponIndex.GetValue(class, g_iIndex[client]);
				CreateWeaponMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && selection == MenuCancel_ExitBack)
			{
				CreateMainMenu(client).Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

Menu CreateWeaponMenu(int client)
{
	int index = g_iIndex[client];
	
	Menu menu = new Menu(WeaponMenuHandler);
	menu.SetTitle("%T", g_WeaponClasses[index], client);
	
	char buffer[128];
	
	Format(buffer, sizeof(buffer), "%T", "SetSkin", client);
	menu.AddItem("skin", buffer);
	
	bool weaponHasSkin = (g_iSkins[client][index] != 0);
	
	if (g_iEnableFloat == 1)
	{
		float fValue = g_fFloatValue[client][index];
		fValue = fValue * 100.0;
		int wear = 100 - RoundFloat(fValue);
		Format(buffer, sizeof(buffer), "%T%d%%", "SetFloat", client, wear);
		menu.AddItem("float", buffer, weaponHasSkin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	if (g_iEnableStatTrak == 1)
	{
		if (g_iStatTrak[client][index] == 1)
		{
			Format(buffer, sizeof(buffer), "%T%T", "StatTrak", client, "On", client);
		}
		else
		{
			Format(buffer, sizeof(buffer), "%T%T", "StatTrak", client, "Off", client);
		}
		menu.AddItem("stattrak", buffer, weaponHasSkin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	if (g_iEnableNameTag == 1)
	{
		StripHtml(g_NameTag[client][index], buffer, sizeof(buffer));
		Format(buffer, sizeof(buffer), "%T%s", "SetNameTag", client, buffer);
		menu.AddItem("nametag", buffer, weaponHasSkin ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	
	return menu;
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char info[32];
				menu.GetItem(selection, info, sizeof(info));
				if(StrEqual(info, "all"))
				{
					CreateAllWeaponsMenu(client).Display(client, MENU_TIME_FOREVER);
				}
				else
				{
					g_smWeaponIndex.GetValue(info, g_iIndex[client]);
					CreateWeaponMenu(client).Display(client, MENU_TIME_FOREVER);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

Menu CreateMainMenu(int client)
{
	char buffer[30];
	Menu menu = new Menu(MainMenuHandler, MENU_ACTIONS_DEFAULT);
	
	menu.SetTitle("%T", "WSMenuTitle", client);
	
	Format(buffer, sizeof(buffer), "%T", "ConfigAllWeapons", client);
	menu.AddItem("all", buffer);
	if (IsPlayerAlive(client))
	{
		char weaponClass[32];
		char weaponName[32];
		
		int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
		for (int i = 0; i < size; i++)
		{
			int weaponEntity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if(weaponEntity != -1 && GetWeaponClass(weaponEntity, weaponClass, sizeof(weaponClass)))
			{
				Format(weaponName, sizeof(weaponName), "%T", weaponClass, client);
				menu.AddItem(weaponClass, weaponName, (i == CS_SLOT_KNIFE && g_iKnife[client] == 0) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
		}
	}
	return menu;
}

Menu CreateKnifeMenu(int client)
{
	Menu menu = new Menu(KnifeMenuHandler);
	menu.SetTitle("%T", "KnifeMenuTitle", client);
	
	char buffer[30];
	Format(buffer, sizeof(buffer), "%T", "OwnKnife", client);
	menu.AddItem("0", buffer, g_iKnife[client] != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_karambit", client);
	menu.AddItem("33", buffer, g_iKnife[client] != 33 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_m9_bayonet", client);
	menu.AddItem("34", buffer, g_iKnife[client] != 34 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_bayonet", client);
	menu.AddItem("35", buffer, g_iKnife[client] != 35 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_survival_bowie", client);
	menu.AddItem("36", buffer, g_iKnife[client] != 36 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_butterfly", client);
	menu.AddItem("37", buffer, g_iKnife[client] != 37 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_flip", client);
	menu.AddItem("38", buffer, g_iKnife[client] != 38 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_push", client);
	menu.AddItem("39", buffer, g_iKnife[client] != 39 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_tactical", client);
	menu.AddItem("40", buffer, g_iKnife[client] != 40 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_falchion", client);
	menu.AddItem("41", buffer, g_iKnife[client] != 41 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "weapon_knife_gut", client);
	menu.AddItem("42", buffer, g_iKnife[client] != 42 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	return menu;
}

public int KnifeMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char knifeIdStr[32];
				menu.GetItem(selection, knifeIdStr, sizeof(knifeIdStr));
				int knifeId = StringToInt(knifeIdStr);
				
				g_iKnife[client] = knifeId;
				char updateFields[50];
				Format(updateFields, sizeof(updateFields), "knife = %d", knifeId);
				UpdatePlayerData(client, updateFields);
				
				RefreshWeapon(client, knifeId, knifeId == 0);
				
				CreateKnifeMenu(client).DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

Menu CreateLanguageMenu(int client)
{
	Menu menu = new Menu(LanguageMenuHandler);
	menu.SetTitle("%T", "ChooseLanguage", client);
	
	char buffer[4];
	
	for (int i = 0; i < sizeof(g_Language); i++)
	{
		if(strlen(g_Language[i]) == 0)
			break;
		IntToString(i, buffer, sizeof(buffer));
		menu.AddItem(buffer, g_Language[i]);
	}
	
	return menu;
}

public int LanguageMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsClientInGame(client))
			{
				char langIndexStr[4];
				menu.GetItem(selection, langIndexStr, sizeof(langIndexStr));
				int langIndex = StringToInt(langIndexStr);
				
				g_iClientLanguage[client] = langIndex;
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}
