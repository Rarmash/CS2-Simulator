package com.rarmash.cs2_simulator.skinspecs;

public enum WeaponType {
    PISTOL ("Pistol"),
    SMG ("SMG"),
    SNIPER_RIFLE ("Sniper rifle"),
    RIFLE ("Rifle"),
    KNIFE ("Knife"),
    SHOTGUN ("Shotgun"),
    MACHINE_GUN ("Machine gun"),
    GLOVES ("Gloves"),
    EQUIPMENT ("Equipment");

    private String weaponType;

    WeaponType(String weaponTypeString) {
        this.weaponType = weaponTypeString;
    }

    public String getWeaponTypeString() {
        return weaponType;
    }

    public static WeaponType fromString(String weaponTypeString) {
        for (WeaponType weapon : WeaponType.values()) {
            if (weapon.getWeaponTypeString().equalsIgnoreCase(weaponTypeString)) {
                return weapon;
            }
        }
        throw new IllegalArgumentException("No enum constant for weapon type title: " + weaponTypeString);
    }

    @Override
    public String toString() {
        return "WeaponType {" +
                "weaponType='" + weaponType + '\'' +
                '}';
    }
}
