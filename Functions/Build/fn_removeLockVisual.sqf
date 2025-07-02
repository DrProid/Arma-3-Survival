/*
 Function: BLWK_fnc_removeLockVisual

 Description:
   Removes the floating visual marker (e.g., sphere) attached to the given object,
   typically called when the object is locked.

 Parameters:
   0: _object <OBJECT> - The object whose lock visual marker should be removed.

 Returns:
   NOTHING
*/
scriptName "BLWK_fnc_removeLockVisual";

params ["_object"];

if (!isNull _object) then {
    private _marker = _object getVariable ["BLWK_lockVisual", objNull];
    if (!isNull _marker) then {
        deleteVehicle _marker;
        _object setVariable ["BLWK_lockVisual", objNull, true];
    };
};
