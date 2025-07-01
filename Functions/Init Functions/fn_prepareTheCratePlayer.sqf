/* ----------------------------------------------------------------------------
Function: BLWK_fnc_prepareTheCratePlayer

Description:
	Creates The Crate icon on the player's screen.
	Adds actions for the The Crate's manipulation.
	Adds an event to tell players how to make medkits with it.

	Executed from "BLWK_fnc_preparePlayArea"

Parameters:
	0: _mainCrate : <OBJECT> - The Crate

Returns:
	NOTHING

Examples:
    (begin example)

		[_crate] spawn BLWK_fnc_prepareTheCratePlayer;

    (end)

Author(s):
	Hilltop(Willtop) & omNomios,
	Modified by: Ansible2 // Cipher
---------------------------------------------------------------------------- */
//CIPHER COMMENT: it might be better to just have a waitUntil{!isNil "BLWK_mainCrate"} from the publicvar and put this in the initPlayerLocal

#define SCRIPT_NAME "BLWK_fnc_prepareTheCratePlayer"
scriptName SCRIPT_NAME;

if (!canSuspend) exitWith {
	["Needs to executed in scheduled, now running in scheduled...",true] call KISKA_fnc_log;
	_this spawn BLWK_fnc_prepareTheCratePlayer;
};

params ["_mainCrate"];

// headless and dedicated servers just need the global set
if (!hasInterface) exitWith {BLWK_mainCrate = _mainCrate};


waitUntil {
	sleep 0.1;
	!isNil "BLWK_pointsForHeal"
};

// hosted server will already have it defined
if (isNil "BLWK_mainCrate") then {
	BLWK_mainCrate = _mainCrate;
};

// Add an action to the crate to buy a magazine based on player's current weapon
_mainCrate addAction [
	format ["<t color='#ff00ff'>-- Buy Magazine %1p --</t>", BLWK_IRP_magazines], // Display action text with cost
	{
    	params ["_target", "_caller"]; // _target = crate, _caller = player

		// Check if can't afford. Price is same you would earn from item reclaimer.
		if ((missionNamespace getVariable ["BLWK_playerKillPoints",0]) < BLWK_IRP_magazines) exitWith {
			["Not enough points to buy magazine."] call KISKA_fnc_errorNotification;
			playSound3D ["a3\sounds_f\sfx\hint-2.wss", _caller];
		};

		// Check if player is not holding a weapon.
		if (currentWeapon _caller == "") exitWith {
			["No weapon in players hands."] call KISKA_fnc_errorNotification;
			playSound3D ["a3\sounds_f\sfx\hint-2.wss", _caller];
		};

		// Get the magazine for the current weapon and muzzle selected
		private _curMag = currentMagazine _caller;
		private _mag = if (_curMag != "") then { _curMag } else { (compatibleMagazines [currentWeapon _caller, currentMuzzle _caller]) select 0 };
		private _magName = getText (configFile >> "CfgMagazines" >> _mag >> "displayName");
		// Try to add the mag to uniform
		if (_caller canAddItemToUniform _mag) then {
			_caller addItemToUniform _mag;
			[format ["%1 placed in your uniform.", _magName]] call KISKA_fnc_notification;
			playSound3D ["A3\Sounds_F\sfx\blip1.wss", _caller];
			[BLWK_IRP_magazines] call BLWK_fnc_subtractPoints;

		// Else, try vest
		} else {
			if (_caller canAddItemToVest _mag) then {
				_caller addItemToVest _mag;
				[format ["%1 placed in your vest.", _magName]] call KISKA_fnc_notification;
				playSound3D ["A3\Sounds_F\sfx\blip1.wss", _caller];
				[BLWK_IRP_magazines] call BLWK_fnc_subtractPoints;

			// Else, try backpack
			} else {
				if (_caller canAddItemToBackpack _mag) then {
					_caller addItemToBackpack _mag;
					[format ["%1 placed in your backpack.", _magName]] call KISKA_fnc_notification;
					playSound3D ["A3\Sounds_F\sfx\blip1.wss", _caller];
					[BLWK_IRP_magazines] call BLWK_fnc_subtractPoints;

				// Else, try putting it in the box
				} else {
					if (_target canAdd _mag) then {
						_target addMagazineCargoGlobal [_mag, 1];
						[format ["%1 placed in crate inventory.", _magName]] call KISKA_fnc_notification;
						playSound3D ["A3\Sounds_F\sfx\blip1.wss", _caller];
						[BLWK_IRP_magazines] call BLWK_fnc_subtractPoints;

					// No space anywhere
					} else {
						["No space to put the magazine!"] call KISKA_fnc_errorNotification;
						playSound3D ["a3\sounds_f\sfx\hint-2.wss", _caller];
					}
				};
			};
		};

	},
	nil,            // arguments (none)
	998,              // priority
	false,          // showWindow
	false,			// hideOnUse
	"true",         // condition (always available)
	"hasInterface", // only for players
	2.5              // distance
];

private _healString = ["<t color='#ff0000'>-- Heal Yourself ",BLWK_pointsForHeal,"p --</t>"] joinString "";
[
	_mainCrate,
	_healString,
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa",
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa",
	"_this distance _target < 2",
	"_caller distance _target < 2",
	{},
	{},
	{
		[_this select 1] call BLWK_fnc_healPlayer;
	},
	{},
	[],
	2,
	2.5,
	false,
	false,
	false
] call BIS_fnc_holdActionAdd;

[_mainCrate] call BLWK_fnc_addOpenShopAction;

[_mainCrate] call BLWK_fnc_addBuildableObjectActions;

// Admin only action to reveal enemies if they are hidden somewhere and the wave won't end.
_mainCrate addAction [
	"<t color='#ffaa00'>[Workaround] Reveal Enemies</t>",
	{
		{player reveal [_x, 4]} forEach BLWK_mustKillArray;
	},
	nil,
	1,
	false,
	true,
	"true",
	"hasInterface",
	2
];

// Add Jeroen Limited Arsenal
_mainCrate call jn_fnc_arsenal_init;



_mainCrate addEventHandler ["ContainerOpened",{
	params ["_mainCrate"];

	[ format ["You can place %1 First Aid Kits in the The Crate to make automatically make a Medkit",BLWK_faksToMakeMedkit] ] call KISKA_fnc_notification;
	// only show once
	_mainCrate removeEventHandler ["ContainerOpened",_thisEventHandler];
}];
// start and end medkit check loop on server when openned and closed
_mainCrate addEventHandler ["ContainerOpened",{
	player setVariable ["BLWK_lookingInTheCrate",true,2];
	remoteExec ["BLWK_fnc_faksToMedkitLoop",2];
}];
_mainCrate addEventHandler ["ContainerClosed",{
	player setVariable ["BLWK_lookingInTheCrate",false,2];
}];


addMissionEventHandler ["Draw3D",{
	drawIcon3D ["", [1,1,1,0.70], (getPosATLVisual BLWK_mainCrate) vectorAdd [0, 0, 1.5], 1, 1, 0, "The Crate", 0, 0.04, "RobotoCondensed", "center", true];
}];

BLWK_mainCrate setVariable ["ace_cookoff_enable", false];


[BLWK_mainCrate] call BLWK_fnc_addAllowDamageEH;
