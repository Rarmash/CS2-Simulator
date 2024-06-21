package com.rarmash.cs2_simulator.enums;

public enum Knife {
    BAYONET ("Bayonet"),
    BUTTERFLY ("Butterfly Knife"),
    FALCHION ("Falchion Knife"),
    FLIP ("Flip Knife"),
    GUT ("Gut Knife"),
    HUNTSMAN ("Huntsman"),
    KARAMBIT ("Karambit"),
    M9_BAYONET ("M9 Bayonet"),
    SHADOW_DAGGERS ("Shadow Daggers"),
    NAVAJA ("Navaja Knife"),
    STILETTO ("Stiletto Knife"),
    TALON ("Talon Knife"),
    URSUS ("Ursus Knife"),
    BOWIE ("Bowie Knife"),
    SKELETON ("Skeleton Knife"),
    PARACORD ("Paracord Knife"),
    SURVIVAL ("Survival Knife"),
    NOMAD ("Nomad Knife"),
    CLASSIC ("Classic Knife"),
    KUKRI ("Kukri Knife");

    private final String knifeTitle;

    Knife(String knifeTitle) {
        this.knifeTitle = knifeTitle;
    }

    public String getKnifeTitle() {
        return knifeTitle;
    }

    public static Knife fromString(String knifeTitleString) {
        for (Knife knife : Knife.values()) {
            if (knife.getKnifeTitle().equalsIgnoreCase(knifeTitleString)) {
                return knife;
            }
        }
        throw new IllegalArgumentException("No enum constant for knife title: " + knifeTitleString);
    }

    @Override
    public String toString() {
        return "Knife {" +
                "knifeTitle='" + knifeTitle + '\'' +
                '}';
    }
}
