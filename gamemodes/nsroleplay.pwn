/*
						||\     ||  ||||||||  ||||||||||   |||||||||
						||\\    ||  ||        ||       ||  ||      ||
						|| \\   ||  ||        ||       ||  ||      ||
						||  \\  ||  ||||||||  |||||||||    |||||||||
						||   \\ ||        ||  ||       ||  ||
						||    \\||        ||  ||       ||  ||
						||     \||  ||||||||  ||       ||  ||

								  CREATED BY JASKARAN SINGH

						  Copyright (C) 2018, Netscrew Technologies

									All rights reserved

	Redistribution and use in any form, with or without modification, are not permitted, in any case.
*/

#include <includes>
#include <defines>
#include <mysql>
#include <colors>

native WP_Hash(buffer[], len, const str[]);

// ---- Enums ----
enum PlayerInfo {
	playerName[255],
	playerEmail[255],
	playerPassword[129],
	playerSex,
	playerSkin,
	Float:playerSpawnX,
	Float:playerSpawnY,
	Float:playerSpawnZ,
	Float:playerSpawnA,
	playerRegHour,
	playerRegMin,
	playerRegSec,
	playerRegDay,
	playerRegMonth,
	playerRegYear,
	playerAffiliateId,
	playerLoginSec,
	playerLoginMin,
	playerLoginHour,
	playerLoginDay,
	playerLoginMonth,
	playerLoginYear
}
new Player[MAX_PLAYERS][PlayerInfo];

enum dialogs {
	DIALOG_REGISTER_1,
	DIALOG_REGISTER_2,
	DIALOG_REGISTER_3,
	DIALOG_REGISTER_4,
	DIALOG_REGISTER_5,
	DIALOG_REGISTER_6,
	DIALOG_LOGIN
}

// ---- Variable Declarations ----
new MySQL:g_SQL;

main() { }

// ---- Forward Declarations ----
forward MysqlConnection();
forward CheckAccountExist(playerid);
forward OnCheckAccountExist(playerid);
forward PlayerRegister(playerid);
forward OnPlayerRegister(playerid);
forward PlayerLogin(playerid);
forward OnPlayerLogin(playerid);
forward AssignAffiliateId(playerid);
forward OnAssignAffiliateId(playerid, affiliateid);
forward CheckReferralId(playerid, affiliateid);
forward RegisterLog(playerid);
forward LoginLog(playerid);

// ---- Built - in Functions ----
public OnGameModeInit() {
	MysqlConnection();

	printf("----------- Netscrew Roleplay -----------\n");
	SetGameModeText(GameMode);
	ShowPlayerMarkers(0);
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(0);
	UsePlayerPedAnims();

	return 1;
}

public OnGameModeExit() {
	mysql_close(g_SQL);

	return 1;
}

public OnPlayerConnect(playerid) {
	CheckAccountExist(playerid);

	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
	switch(dialogid)
	{
		case DIALOG_REGISTER_1:
		{
			if(response)
			{
				strmid(Player[playerid][playerEmail], inputtext, 0, strlen(inputtext), 255);
				ShowPlayerDialog(playerid, DIALOG_REGISTER_2, DIALOG_STYLE_PASSWORD, "Account Registration", "Please enter a password below.", "Next", "Back");
			}
			else
				return Kick(playerid);
		}

		case DIALOG_REGISTER_2:
		{
			if(response)
			{
				if(strlen(inputtext) < 5)
				{
					// @TODO Dialog not showing
					ShowPlayerDialog(playerid, DIALOG_REGISTER_2, DIALOG_STYLE_PASSWORD, ""COL_WHITE"Account Registration", ""COL_WHITE"Your password must contain at least 5 characters.\n"COL_WHITE"Please enter a password below to register your account.", "Next", "Back");
				}

				WP_Hash(Player[playerid][playerPassword], 129, inputtext);

				ShowPlayerDialog(playerid, DIALOG_REGISTER_3, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Account Registration", ""COL_WHITE"Please choose your sex.", "Male", "Female");
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_REGISTER_1, DIALOG_STYLE_INPUT, ""COL_WHITE"Account Registration", ""COL_WHITE"Please enter your email below to register your account.", "Next", "Cancel");
			}
		}

		case DIALOG_REGISTER_3:
		{
			if(response)
			{
				Player[playerid][playerSex] = 0;  // Male
				Player[playerid][playerSkin] = 250;
			}
			else
			{
				Player[playerid][playerSex] = 1;  // Female
				Player[playerid][playerSkin] = 56;
			}

			ShowPlayerDialog(playerid, DIALOG_REGISTER_4, DIALOG_STYLE_INPUT, ""COL_WHITE"Account Registration", ""COL_WHITE"Please enter the referral ID, if you have one. Leave empty if you don't have any.", "Next", "Back");
		}

		case DIALOG_REGISTER_4:
		{
			if(response) {
				if(strlen(inputtext) < 1) {
					PlayerRegister(playerid);
				}
				else {
					new query[1024];
					mysql_format(g_SQL, query, sizeof(query), "SELECT `pname` FROM `players` WHERE `paffiliateid` = '%d' LIMIT 1", strval(inputtext));
					mysql_tquery(g_SQL, query, "CheckReferralId", "ii", playerid, strval(inputtext));
				}
			}
			else {
				ShowPlayerDialog(playerid, DIALOG_REGISTER_3, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Account Registration", ""COL_WHITE"Please choose your sex.", "Male", "Female");
			}
		}

		case DIALOG_REGISTER_5:
		{
			if(response) {
				PlayerRegister(playerid);
			}
			else {
				ShowPlayerDialog(playerid, DIALOG_REGISTER_4, DIALOG_STYLE_INPUT, ""COL_WHITE"Account Registration", ""COL_WHITE"Please enter the referral ID, if you have one. Leave empty if you don't have any.", "Next", "Back");
			}
		}

		case DIALOG_LOGIN:
		{
			if(response)
			{
				new hashpass[129], name[255];
				name = GetName(playerid);

				WP_Hash(hashpass, sizeof(hashpass), inputtext);

				if(strcmp(hashpass, Player[playerid][playerPassword]) == 0)
				{
					PlayerLogin(playerid);
				}
				else
					ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""COL_WHITE"Login", ""COL_RED"You have entered an incorrect password.\n"COL_WHITE"Type your password below to login.", "Login", "Quit");
			}
			else
				return Kick(playerid);
		}
	}

	return 1;
}

public MysqlConnection() {
	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE);
	mysql_log(ERROR | DEBUG);
	return 1;
}

public CheckAccountExist(playerid) {
	new query[256], name[255];
	name = GetName(playerid);

	mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM `players` WHERE `pname` = '%e' LIMIT 1", name);
	mysql_tquery(g_SQL, query, "OnCheckAccountExist", "i", playerid);

	return 1;
}

public OnCheckAccountExist(playerid) {
	if(cache_num_rows() > 0) {
		new logintext[256];
		cache_get_value(0, "ppassword", Player[playerid][playerPassword], 129);
		cache_get_value_name_int(0, "plogins", Player[playerid][playerLoginSec]);
		cache_get_value_name_int(0, "ploginm", Player[playerid][playerLoginMin]);
		cache_get_value_name_int(0, "ploginh", Player[playerid][playerLoginHour]);
		cache_get_value_name_int(0, "ploginday", Player[playerid][playerLoginDay]);
		cache_get_value_name_int(0, "ploginmon", Player[playerid][playerLoginMonth]);
		cache_get_value_name_int(0, "ploginyear", Player[playerid][playerLoginYear]);
		cache_get_value_name_int(0, "plogins", Player[playerid][playerLoginSec]);
		cache_get_value_name_int(0, "ploginm", Player[playerid][playerLoginMin]);
		cache_get_value_name_int(0, "ploginh", Player[playerid][playerLoginHour]);
		cache_get_value_name_int(0, "ploginday", Player[playerid][playerLoginDay]);
		cache_get_value_name_int(0, "ploginmon", Player[playerid][playerLoginMonth]);
		cache_get_value_name_int(0, "ploginyear", Player[playerid][playerLoginYear]);

		format(logintext, sizeof(logintext), ""COL_WHITE"""We found an account with this name. Please enter your password below to login. (Last Login: %d/%d/%d at %d:%d:%d)", Player[playerid][playerLoginDay], Player[playerid][playerLoginMonth], Player[playerid][playerLoginYear], Player[playerid][playerLoginHour], Player[playerid][playerLoginMin], Player[playerid][playerLoginSec]);

		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""COL_WHITE"Account Login", logintext, "Login", "Quit");
	}
	else
		ShowPlayerDialog(playerid, DIALOG_REGISTER_1, DIALOG_STYLE_INPUT, ""COL_WHITE"Account Registration", ""COL_WHITE"Please enter your email below to register your account.", "Next", "Cancel");

	return 1;
}

stock GetName(playerid) {
	new name[255];
	GetPlayerName(playerid, name, sizeof(name));

	return name;
}

public PlayerRegister(playerid) {
	new query[1024], name[255], query2[512], query3[512];

	name = GetName(playerid);

	Player[playerid][playerName] = name;
	Player[playerid][playerSpawnX] = 1685.6904;
	Player[playerid][playerSpawnY] = -2240.9397;
	Player[playerid][playerSpawnZ] = 13.5469;
	Player[playerid][playerSpawnA] = 180.0;

	gettime(Player[playerid][playerRegHour], Player[playerid][playerRegMin], Player[playerid][playerRegSec]);
	getdate(Player[playerid][playerRegYear], Player[playerid][playerRegMonth], Player[playerid][playerRegDay]);

	Player[playerid][playerLoginHour] = Player[playerid][playerRegHour];
	Player[playerid][playerLoginMin] = Player[playerid][playerRegMin];
	Player[playerid][playerLoginSec] = Player[playerid][playerRegSec];

	Player[playerid][playerLoginDay] = Player[playerid][playerRegDay];
	Player[playerid][playerLoginMonth] = Player[playerid][playerRegMonth];
	Player[playerid][playerLoginYear] = Player[playerid][playerRegYear];

	mysql_format(g_SQL, query, sizeof(query), "INSERT INTO `players`(`pname`, `pemail`, `ppassword`, `psex`, `pskin`) VALUES ('%e', '%e', '%e', '%d', '%d')", Player[playerid][playerName], Player[playerid][playerEmail], Player[playerid][playerPassword], Player[playerid][playerSex], Player[playerid][playerSkin]);
	mysql_tquery(g_SQL, query);

	mysql_format(g_SQL, query2, sizeof(query2), "UPDATE `players` SET `pspawnx` = '%f', `pspawny` = '%f', `pspawnz` = '%f', `pspawna` = '%f', `pregh` = '%d', `pregm` = '%d', `pregs` = '%d' WHERE `pname` = '%e'", Player[playerid][playerSpawnX], Player[playerid][playerSpawnY], Player[playerid][playerSpawnZ], Player[playerid][playerSpawnA], Player[playerid][playerRegHour], Player[playerid][playerRegMin], Player[playerid][playerRegSec], Player[playerid][playerName]);
	mysql_tquery(g_SQL, query2);

	mysql_format(g_SQL, query3, sizeof(query3), "UPDATE `players` SET `pregday` = '%d', `pregmon` = '%d', `pregyear` = '%d' WHERE `pname` = '%e'", Player[playerid][playerRegDay], Player[playerid][playerRegMonth], Player[playerid][playerRegYear], Player[playerid][playerName]);
	mysql_tquery(g_SQL, query3);

	RegisterLog(playerid);
	LoginLog(playerid);

	AssignAffiliateId(playerid);

	OnPlayerRegister(playerid);

	SetSpawnInfo(playerid, 0, Player[playerid][playerSkin], Player[playerid][playerSpawnX], Player[playerid][playerSpawnY], Player[playerid][playerSpawnZ], Player[playerid][playerSpawnA], -1, -1, -1, -1, -1, -1);
	SpawnPlayer(playerid);

	return 1;
}

public OnPlayerRegister(playerid) {
	new text[256];

	ShowPlayerDialog(playerid, DIALOG_REGISTER_6, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Account Registration", ""COL_WHITE"Thank you for registering to the server. We hope you have an amazing experience.", "Okay", "");

	format(text, sizeof(text), "%s has registered to the server.", Player[playerid][playerName]);
	print(text);

	return 1;
}

public PlayerLogin(playerid) {
	new query[256];

	mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM `players` WHERE `pname` = '%e'", GetName(playerid));
	mysql_tquery(g_SQL, query, "OnPlayerLogin", "i", playerid);

	return 1;
}

public OnPlayerLogin(playerid) {
	new text[256];
	cache_get_value(0, "pname", Player[playerid][playerName], 255);
	cache_get_value(0, "pemail", Player[playerid][playerEmail], 255);
	cache_get_value(0, "ppassword", Player[playerid][playerPassword], 129);
	cache_get_value_name_int(0, "psex", Player[playerid][playerSex]);
	cache_get_value_name_int(0, "pskin", Player[playerid][playerSkin]);
	cache_get_value_name_float(0, "pspawnx", Player[playerid][playerSpawnX]);
	cache_get_value_name_float(0, "pspawny", Player[playerid][playerSpawnY]);
	cache_get_value_name_float(0, "pspawnz", Player[playerid][playerSpawnZ]);
	cache_get_value_name_float(0, "pspawna", Player[playerid][playerSpawnA]);
	cache_get_value_name_int(0, "paffiliateid", Player[playerid][playerAffiliateId]);

	gettime(Player[playerid][playerLoginHour], Player[playerid][playerLoginMin], Player[playerid][playerLoginSec]);
	getdate(Player[playerid][playerLoginYear], Player[playerid][playerLoginMonth], Player[playerid][playerLoginDay]);
	
	LoginLog(playerid);

	SetSpawnInfo(playerid, 0, Player[playerid][playerSkin], Player[playerid][playerSpawnX], Player[playerid][playerSpawnY], Player[playerid][playerSpawnZ], Player[playerid][playerSpawnA], -1, -1, -1, -1, -1, -1);
	SpawnPlayer(playerid);

	format(text, sizeof(text), "%s has logged in to the server.", Player[playerid][playerName]);
	printf(text);

	return 1;
}

public AssignAffiliateId(playerid) {
	new query[256], affiliateid;

	affiliateid = 100000 + random(899999);

	mysql_format(g_SQL, query, sizeof(query), "SELECT `paffiliateid` FROM `players` WHERE `paffiliateid` = '%d'", affiliateid);
	mysql_tquery(g_SQL, query, "OnAssignAffiliateId", "ii", playerid, affiliateid);

	return 1;
}

public OnAssignAffiliateId(playerid, affiliateid) {
	new query[1024];

	if(cache_num_rows() > 0) {
		AssignAffiliateId(playerid);
	}
	else {
		Player[playerid][playerAffiliateId] = affiliateid;
		mysql_format(g_SQL, query, sizeof(query), "UPDATE `players` SET `paffiliateid` = '%d' WHERE `pname` = '%e'", affiliateid, Player[playerid][playerName]);
		mysql_tquery(g_SQL, query);
	}

	return 1;
}

public CheckReferralId(playerid, affiliateid) {
	new name[255], text[256];
	if(cache_num_rows() > 0) {
		cache_get_value(0, "pname", name, 255);

		format(text, sizeof(text), ""COL_WHITE"Are you sure that %s referred you?", name);
		ShowPlayerDialog(playerid, DIALOG_REGISTER_5, DIALOG_STYLE_MSGBOX, ""COL_WHITE"Account Registration", text, "Yes", "No");
	}
	else {
		ShowPlayerDialog(playerid, DIALOG_REGISTER_4, DIALOG_STYLE_INPUT, ""COL_WHITE"Account Registration", ""COL_WHITE"You entered an incorrect referral id. Please enter a correct referral ID, if you have one. Leave empty if you don't have any.", "Next", "Back");
	}

	return 1;
}

// -------------------------------------Log Functions---------------------------------------------
public RegisterLog(playerid) {  // Makes log of player registrations
	new query[256];
	mysql_format(g_SQL, query, sizeof(query), "INSERT INTO `registrations`(`pname`, `preghour`, `pregmin`, `pregsec`, `pregday`, `pregmonth`, `pregyear`) VALUES ('%e', '%d', '%d', '%d', '%d', '%d', '%d')", Player[playerid][playerName], Player[playerid][playerRegHour], Player[playerid][playerRegMin], Player[playerid][playerRegSec], Player[playerid][playerRegDay], Player[playerid][playerRegMonth], Player[playerid][playerRegYear]);
	mysql_tquery(g_SQL, query);

	return 1;
}

public LoginLog(playerid) {
	new query[256];
	mysql_format(g_SQL, query, sizeof(query), "INSERT INTO `logins` (`pname`, `plogins`, `ploginm`, `ploginh`, `ploginday`, `ploginmon`, `ploginyear`) VALUES ('%e', '%d', '%d', '%d', '%d', '%d', '%d')", Player[playerid][playerName], Player[playerid][playerLoginSec], Player[playerid][playerLoginMin], Player[playerid][playerLoginHour], Player[playerid][playerLoginMonth], Player[playerid][playerLoginYear]);
	mysql_tquery(g_SQL, query);

	return 1;
}
