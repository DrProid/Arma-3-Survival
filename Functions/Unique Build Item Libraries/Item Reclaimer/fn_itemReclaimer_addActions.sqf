/* ----------------------------------------------------------------------------
Function: BLWK_fnc_itemReclaimer_addActions

Description:
	Add the actions for reclaiming items and accessing the inventory of the item
	 reclaimer.

	Executed from its onSold event added in the config "main build items.hpp"

Parameters:
	0: _reclaimerObject : <OBJECT> - The item reclaimer object

Returns:
	NOTHING

Examples:
    (begin example)
		[anObject] call BLWK_fnc_itemReclaimer_addActions;
    (end)

Author(s):
	Ansible2 // Cipher
---------------------------------------------------------------------------- */
scriptName "BLWK_fnc_itemReclaimer_addActions";

if (!hasInterface) exitWith {};

params ["_reclaimerObject"];

if (isNull _reclaimerObject) exitWith {
	["_reclaimerObject was null, exiting...",true] call KISKA_fnc_log;
	nil
};

_reclaimerObject addAction [
	"Open Item Reclaimer Inventory",	// title
	{
		params ["_target", "_caller"];

		// open up invisible storage box
		_caller action ["Gear",_target getVariable "BLWK_reclaimBox"];
	},
	nil,		// arguments
	200,		// priority
	true,		// showWindow
	true,		// hideOnUse
	"",			// shortcut
	"true", 	// condition
	3			// radius
];

_reclaimerObject addAction [
    "UNPACK ALL",// unpacks all backpacks, removes attachments and ammo
    {
        params ["_target", "_caller"]; // _target is the crate, _caller is the player interacting

        // Call a custom function to process unlocking items
        [_target getVariable "BLWK_reclaimBox"] call BLWK_fnc_unpackEverything;
		
    },
	nil,		// arguments
	199,		// priority
	false,		// showWindow
	true,		// hideOnUse
	"",			// shortcut
	"true", 	// condition
	3			// radius
];

[
	_reclaimerObject,
	"Reclaim Items",
	"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\refuel_ca.paa",
	"\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\refuel_ca.paa",
	"_this distance _target < 3",
	"_caller distance _target < 3",
	{},
	{},
	{
		[_this select 0] call BLWK_fnc_itemReclaimer_reclaim;
		["Items Reclaimed"] call KISKA_fnc_notification;
	},
	{},
	[],
	1,
	200,
	false,
	false
] call BIS_fnc_holdActionAdd;


nil
