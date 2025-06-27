#include "..\..\Headers\Build Objects Properties Defines.hpp"
/* ----------------------------------------------------------------------------
Function: BLWK_fnc_addBuildableObjectActions

Description:
	Adds all the actions to an object in order to manipulate it in the world.

	Executed from "BLWK_fnc_purchaseObject"

Parameters:
	0: _object : <OBJECT> - The object to add the actions to

Returns:
	BOOL

Examples:
    (begin example)

		[myObject] call BLWK_fnc_addBuildableObjectActions;

    (end)

Author(s):
	Ansible2 // Cipher
---------------------------------------------------------------------------- */
scriptName "BLWK_fnc_addBuildableObjectActions";

#define CONDITION "!(_originalTarget getVariable ['BLWK_objectPickedUp',false]) AND !(_originalTarget getVariable ['BLWK_objectLocked',false]) AND {isNil 'BLWK_heldObject'} AND {isNull (objectParent player)}"

if !(hasInterface) exitWith {false};

params [
	["_object",objNull,[objNull]]
];

if (isNull _object) exitWith {
	["Null object passed, will not add actions, exiting...",true] call KISKA_fnc_log;
	false
};

private _actionDistance = ((_object call BIS_fnc_boundingBoxDimensions) select 1) + 2;
if (_actionDistance < 5) then {
	_actionDistance = 5;
};

private _objectType = toLowerANSI (typeOf _object);
private _objectName = "";
private _addSellAction = true;
switch (true) do {
	case (_object isEqualTo (missionNamespace getVariable ["BLWK_randomWeaponBox",objNull])):{
		_objectName = "Random Weapon Box";
		_addSellAction = false;
	};
	case (_object isEqualTo (missionNamespace getVariable ["BLWK_mainCrate",objNull])):{
		_objectName = "The Main Crate";
		_addSellAction = false;
	};
	default {
		// JIP players will not have BLWK_buildableObjectsHash defined right away
		if (isNil "BLWK_buildableObjectsHash") then {
			_objectName = getText(missionConfigFile >> "BLWK_buildableItems" >> _objectType >> "displayName");
			if (_objectName isEqualTo "") then {
				_objectName = [configFile >> "cfgVehicles" >> _objectType] call BIS_fnc_displayName;
			};

		} else {
			_objectName = (BLWK_buildableObjectsHash get _objectType) select DISPLAY_NAME;

		};
	};
};

// CIPHER COMMENT: maybe make sell into a hold action?
// DRPROID COMMENT: I made it a hold action
// sell object
if (_addSellAction) then {
	[
	_object,
	"<t color='#ff0000'><t underline='true'><t font='RobotoCondensedBold'>-- Sell " + _objectName + " Back --</t></t></t>",
	"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\refuel_ca.paa",
	"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\refuel_ca.paa",
	CONDITION + " AND {_this distance _target < " + str _actionDistance + "}",
	"_caller distance _target < " + str _actionDistance,
	{},
	{},
	{
		params ["_object","_caller"];
		//This if statement seems redundant because we are already in an if statement that checks _addSellAction which should already be populated, so we shouldn't see the sell option for these objects anyway
		// if (_object isEqualTo (missionNamespace getVariable ["BLWK_mainCrate",objNull]) OR {_object isEqualTo (missionNamespace getVariable ["BLWK_randomWeaponBox",objNull])}) exitWith {
		// 	["You can't sell this item"] call KISKA_fnc_errorNotification;
		// };
		[_object,_caller] call BLWK_fnc_sellObject;
	},
	{},
	[],
	5, // Action duration in seconds
	90, // Priority
	true, // Remove on completion - Not sure if this matters because the object should be removed anyway, but come back and change to false if BLWK_fnc_sellObject fails in any cases
	false // Show in unconscious state
] call BIS_fnc_holdActionAdd;
};

// move up
_object addAction [
	"<t color='#00ffff'><t underline='true'><t font='RobotoCondensedBold'>-- Move " + _objectName + " Up --</t></t></t>",
	{
		[_this select 0,true] call BLWK_fnc_moveUpOrDown;
	},
	nil,
	95,
	false,
	false,
	"true",
	CONDITION,
	_actionDistance
];


// move down
_object addAction [
	"<t color='#00ff00'><t underline='true'><t font='RobotoCondensedBold'>-- Move " + _objectName + " Down --</t></t></t>",
	{
		[_this select 0,false] call BLWK_fnc_moveUpOrDown;
	},
	nil,
	94,
	false,
	false,
	"true",
	CONDITION,
	_actionDistance
];

// pick up
_object addAction [
	"<t color='#ffffff'><t underline='true'><t font='RobotoCondensedBold'>-- Pickup " + _objectName + " --</t></t></t>",
	{
		params ["_object","_caller"];
		[_object,_caller] spawn BLWK_fnc_pickupObject;
	},
	nil,
	100,
	false,
	false,
	"true",
	CONDITION,
	_actionDistance
];

// rotate left
_object addAction [
	"<t color='#ffff00'><t underline='true'><t font='RobotoCondensedBold'>-- Rotate " + _objectName + " Left --</t></t></t>",
	{
		[_this select 0,false] call BLWK_fnc_rotateObject;
	},
	_object,
	92,
	false,
	false,
	"true",
	CONDITION,
	_actionDistance
];

// rotate right
_object addAction [
	"<t color='#cc33ff'><t underline='true'><t font='RobotoCondensedBold'>-- Rotate " + _objectName + " Right --</t></t></t>",
	{
		[_this select 0,true] call BLWK_fnc_rotateObject;
	},
	nil,
	93,
	false,
	false,
	"true",
	CONDITION,
	_actionDistance
];

// Reset Rotation
_object addAction [
	"<t color='#ff00bf'><t underline='true'><t font='RobotoCondensedBold'>-- Reset " + _objectName + " Rotation --</t></t></t>",
	{
		[_this select 0] call BLWK_fnc_resetObjectRotation;
	},
	nil,
	91,
	false,
	false,
	"true",
	CONDITION,
	_actionDistance
];

// Lock object
_object addAction [
	"<t color='#ff0000'><t underline='true'><t font='RobotoCondensedBold'>-- Lock " + _objectName + " --</t></t></t>",
	{
		params ["_object"];
		_object setVariable ['BLWK_objectLocked', true];
	},
	nil,
	99,
	false,
	false,
	"true",
	CONDITION,
	_actionDistance
];

// Unlock object
_object addAction [
	"<t color='#ff0000'><t underline='true'><t font='RobotoCondensedBold'>-- Unlock " + _objectName + " --</t></t></t>",
	{
		params ["_object"];
		_object setVariable ['BLWK_objectLocked', false];
	},
	nil,
	99,
	false, // showWindow - Why isn't this working?
	false,
	"true",
	"!(_originalTarget getVariable ['BLWK_objectPickedUp',false]) AND (_originalTarget getVariable ['BLWK_objectLocked',false]) AND {isNil 'BLWK_heldObject'} AND {isNull (objectParent player)}",
	_actionDistance
];

true
