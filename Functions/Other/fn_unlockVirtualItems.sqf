/* ----------------------------------------------------------------------------
Function: BLWK_fnc_unlockVirtualItems

Description:
	Checks if there are more than "BLWK_quantityNeededToUnlock" items in the main crate.
    If there are, then it unlocks that item in the virtual arsenal and deletes 10 of them from the crate.
	
	Executed from the action added in "BLWK_fnc_prepareTheCratePlayer"
	
Parameters:
	0: _crate : <OBJECT> - The main crate

Returns:
	NOTHING

Examples:
    (begin example)

		[anObject] call BLWK_fnc_unlockVirtualItems;

    (end)

Author(s):
	DrProid
---------------------------------------------------------------------------- */

params ["_crate"]; // The crate being processed

private _fn_stripWeapon = { // takes all attachments and ammo out of a weapon

    // Parameters: [_crate,  [weapon, muzzle, flashlight, optics, [magazine, ammo], [magazine, ammo], bipod]]
    params ["_crate", "_weaponItem"];

    private _weaponClass = _weaponItem select 0; // Weapon class name
    _crate addWeaponCargoGlobal [_weaponClass, 1]; // Add weapon to the crate

    private _muzzle = _weaponItem select 1;     // Muzzle attachment
    if (_muzzle != "") then {
        _crate addItemCargoGlobal [_muzzle, 1]; // Add muzzle attachment
    };

    private _pointer = _weaponItem select 2;    // Pointer attachment
    if (_pointer != "") then {
        _crate addItemCargoGlobal [_pointer, 1]; // Add pointer attachment
    };

    private _optic = _weaponItem select 3;      // Optic attachment
    if (_optic != "") then {
        _crate addItemCargoGlobal [_optic, 1]; // Add optic attachment
    };

    private _underBarrel = _weaponItem select 6; // Under-barrel attachments (if any)
    if (_underBarrel != "") then {
        _crate addItemCargoGlobal [_underBarrel, 1]; // Add under-barrel attachment
    };

    private _primaryMagazine = _weaponItem select 4;   // Primary magazine and ammo count
    if (_primaryMagazine isNotEqualTo []) then {
        private _ammoClassName = _primaryMagazine select 0;
        private _ammoCount = _primaryMagazine select 1;
        _crate addMagazineAmmoCargo [_ammoClassName, 1, _ammoCount];
    };

    private _secondaryMagazine = _weaponItem select 5;   // Secondary magazine and ammo count
    if (_secondaryMagazine isNotEqualTo []) then {
        private _ammoClassName = _secondaryMagazine select 0;
        private _ammoCount = _secondaryMagazine select 1;
        _crate addMagazineAmmoCargo [_ammoClassName, 1, _ammoCount];
    };
};

////// UNPACKING ALL CONTAINERS //////////
hint format ["Unpacking Containers in %1", _crate];
private _allContainers = everyContainer _crate; // every backpack, uniform and vest
{
    private _containerClassName = _x select 0; // we don't actually need this

    private _containerObject = _x select 1;

    private _allItems = itemCargo _containerObject; // Non-weapons, including uniforms and vestItems - array of strings
    {
        _crate addItemCargoGlobal [_x, 1]; // Add each item to the crate
    } forEach _allItems;
    
    private _allBackpacks = backpackCargo _containerObject; // Backpacks - array of strings
    {
        _crate addBackpackCargoGlobal [_x, 1]; // Add each backpack to the crate
    } forEach _allBackpacks;

    private _allMagazinesAmmo = magazinesAmmoCargo _containerObject; // Magazines Ammo  - array of arrays
    {
        private _ammoClassName = _x select 0;
        private _ammoCount = _x select 1;
        _crate addMagazineAmmoCargo [_ammoClassName, 1, _ammoCount]; // Add magazine with the correct count
    } forEach _allMagazinesAmmo;

    private _allWeaponItems = weaponsItemsCargo _containerObject; // Weapons and weapon attachments including loaded ammo - array of arrays
    {
        [_crate, _x] call _fn_stripWeapon;

    } forEach _allWeaponItems;

    //empty this container
    clearItemCargoGlobal _containerObject;
    clearBackpackCargoGlobal _containerObject;
    clearWeaponCargoGlobal _containerObject;   // Clears weapons
    clearMagazineCargoGlobal _containerObject; // Clears magazines

} forEach _allContainers;

/////////// TAKE OFF ALL WEAPON ATTACHMENTS AND UNLOAD AMMO ///////////////
hint format ["Stripping weapons in %1", _crate];
private _allWeaponItems = weaponsItemsCargo _crate; // Weapons and weapon attachments including loaded ammo - array of arrays
clearWeaponCargoGlobal _crate;   // Clears weapons
{
    [_crate, _x] call _fn_stripWeapon;

} forEach _allWeaponItems;

////////// REPACK - CONSOLIDATE NON FULL MAGAZINES ///////////

// make a list of all magazines along with ammocount
// clear all magazines from the _crate
// we would iterate over the list of mags counting the total number of bullets
    // I guess we would need some way to know what the max capacity of the magazine is??? 
    // do we also want to account for skins (camoflague)? is it possible to know if two magazines are the same if they have different class names?
    // then we could work out how many full magazines that would be and add them to _crate
    // then any modulo would go back into one non-full mag which would be added to _crate

/////////// CONVERT INVENTORY ITEMS INTO VIRTUAL ARSENAL ITEMS ///////////////

// next we count everything in the _crate
// weapons
// items
// only full magazines
// etc
// and for each:
    // if the item already exists in the "unlocked array" AND the item reclaimer exists then:
        // add that quantity of items to the reclaimer inventory
        // remove the items from the _crate
        // we are basically just moving them to the reclaimer to make things easier, they are no longer needed and may as well be reclaimed.
    // else:
        // if the item is greater than or equal to some "unlock amount" then:
            // subtract that "unlock amount" of that item from the _crate (most of the add functions now take negative numbers)
            // add the item to the "unlocked array"
            // update virtual arsenal with the new "unlocked array" or add the item to the arsenal, whichever makes more sense...
            // send whatever is left over to the reclaimer
