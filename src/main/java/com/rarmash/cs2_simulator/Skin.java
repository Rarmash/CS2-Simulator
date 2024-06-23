package com.rarmash.cs2_simulator;

import com.rarmash.cs2_simulator.enums.Gloves;
import com.rarmash.cs2_simulator.enums.Knife;
import com.rarmash.cs2_simulator.skinspecs.Exterior;
import com.rarmash.cs2_simulator.skinspecs.Rarity;
import com.rarmash.cs2_simulator.enums.Weapon;
import com.rarmash.cs2_simulator.skinspecs.WeaponType;

public class Skin {
    private final String name;
    private final String skinImage;
    private double skinFloat;
    private final double float_top;
    private final double float_bottom;
    private boolean isStattrak;
    private final boolean isSouvenir;
    private final Rarity rarity;
    private Exterior exterior;
    private final WeaponType weaponType;
    private final Object item;

    public Skin(String name, String skinImage, double float_top, double float_bottom, boolean isSouvenir, Rarity rarity, WeaponType weaponType, Weapon weapon) {
        this.name = name;
        this.skinImage = skinImage;
        this.float_top = float_top;
        this.float_bottom = float_bottom;
        this.isSouvenir = isSouvenir;
        this.rarity = rarity;
        this.weaponType = weaponType;
        this.item = weapon;
    }

    public Skin(String name, String skinImage, double float_top, double float_bottom, boolean isSouvenir, Rarity rarity, WeaponType weaponType, Knife knife) {
        this.name = name;
        this.skinImage = skinImage;
        this.float_top = float_top;
        this.float_bottom = float_bottom;
        this.isSouvenir = isSouvenir;
        this.rarity = rarity;
        this.weaponType = weaponType;
        this.item = knife;
    }

    public Skin(String name, String skinImage, double float_top, double float_bottom, boolean isSouvenir, Rarity rarity, WeaponType weaponType, Gloves gloves) {
        this.name = name;
        this.skinImage = skinImage;
        this.float_top = float_top;
        this.float_bottom = float_bottom;
        this.isSouvenir = isSouvenir;
        this.rarity = rarity;
        this.weaponType = weaponType;
        this.item = gloves;
    }

    public String getName() {
        return name;
    }

    public String getSkinImage() {
        return skinImage;
    }

    public void setSkinFloat(double skinFloat) {
        this.skinFloat = skinFloat;
    }

    public double getSkinFloat() {
        return skinFloat;
    }

    public double getFloat_top() {
        return float_top;
    }

    public double getFloat_bottom() {
        return float_bottom;
    }

    public void setIsStattrak(boolean isStattrak) {
        this.isStattrak = isStattrak;
    }

    public boolean getIsStattrak() {
        return isStattrak;
    }

    public boolean isSouvenir() {
        return isSouvenir;
    }

    public Rarity getRarity() {
        return rarity;
    }

    public void setExterior(Exterior exterior) {
        this.exterior = exterior;
    }

    public Exterior getExterior() {
        return exterior;
    }

    public WeaponType getWeaponType() {
        return weaponType;
    }

    public Object getItem() {
        return item;
    }

    @Override
    public String toString() {
        String string = "";
//        if (weaponType == WeaponType.KNIFE || weaponType == WeaponType.GLOVES) {
//            string += "\u2605 ";
//        }
        if (isStattrak) {
            string += "StatTrak™ ";
        }
        if (weaponType != WeaponType.KNIFE && weaponType != WeaponType.GLOVES) {
            string += ((Weapon) item).getWeaponTitle();
        } else if (weaponType == WeaponType.KNIFE) {
            string += ((Knife) item).getKnifeTitle();
        } else if (weaponType == WeaponType.GLOVES) {
            string += ((Gloves) item).getGlovesTitle();
        }
        string += " | " + name;
        string += "\nRarity: " + rarity.getRarityTitle();
        if (!(weaponType == WeaponType.KNIFE && name == "Vanilla")) {
            string += "\nFloat: " + getSkinFloat();
            string += "\nExterior: " + getExterior().getExteriorTitle();
        }
        return string;
    }
}
