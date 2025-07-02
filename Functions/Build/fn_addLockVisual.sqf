/*
    Function: BLWK_fnc_addLockVisual
    Description:
        Adds the "unlocked" floating marker visual to the given object.
        Creates and attaches a Sign_Sphere10cm_F marker slightly above the object.
    Params:
        0: _obj (OBJECT) - The object to add the visual to.
    Returns:
        Nothing.
*/

#include "..\..\Headers\Build Objects Properties Defines.hpp"

scriptName "BLWK_fnc_addLockVisual";

params ["_obj"];

if (isNull _obj) exitWith {
    ["BLWK_fnc_addLockVisual: passed object is null, exiting.", true] call KISKA_fnc_log;
    nil
};

private _bbox = boundingBoxReal _obj; // Get the bounding box corners
private _min = _bbox select 0;
private _max = _bbox select 1;

// Calculate width, depth, height
private _sizeX = abs ((_max select 0) - (_min select 0)); // width
private _sizeY = abs ((_max select 1) - (_min select 1)); // depth
private _sizeZ = abs ((_max select 2) - (_min select 2)); // height

// Find the smallest dimension
private _smallest = _sizeX min _sizeY min _sizeZ;

// Red "UNLOCKED" sphere
private _redPos = getPosWorld _obj;
private _marker = createSimpleObject ["Sign_Sphere100cm_F", [0,0,0]];
_marker setObjectTextureGlobal [0, "#(rgb,8,8,3)color(1,0,0,0.01)"]; // Red
_marker attachTo [_obj, [0,0,0]];
_marker setObjectScale ([_smallest, 0.5, 5] call BIS_fnc_clamp);

_obj setVariable ["BLWK_lockVisual", _marker, true];