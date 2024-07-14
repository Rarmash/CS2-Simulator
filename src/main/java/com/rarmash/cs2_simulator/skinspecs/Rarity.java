package com.rarmash.cs2_simulator.skinspecs;

import java.awt.*;

public enum Rarity {
    CONTRABAND ("Contraband", new Color(255, 174, 57)),
    EXTRAORDINARY ("Extraordinary", new Color(235, 75, 75)),
    COVERT ("Covert", new Color(235, 75, 75)),
    CLASSIFIED ("Classified", new Color(211, 46, 230)),
    RESTRICTED ("Restricted", new Color(136, 71, 255)),
    MIL_SPEC ("Mil-Spec Grade", new Color(75, 105, 255)),
    INDUSTRIAL ("Industrial Grade", new Color(94, 152, 217)),
    CONSUMER ("Consumer Grade", new Color(176, 195, 217));

    private final String rarityTitle;
    private final Color color;

    Rarity(String rarityTitle, Color color) {
        this.rarityTitle = rarityTitle;
        this.color = color;
    }

    public static int getRarityIndex(Rarity rarity) {
        return switch (rarity) {
            case CONTRABAND -> 0;
            case EXTRAORDINARY -> 1;
            case COVERT -> 2;
            case CLASSIFIED -> 3;
            case RESTRICTED -> 4;
            case MIL_SPEC -> 5;
            case INDUSTRIAL -> 6;
            case CONSUMER -> 7;
        };
    }

    public String getRarityTitle() {
        return rarityTitle;
    }

    public Color getColor() {
        return color;
    }

    public static Rarity fromString(String rarityTitle) {
        for (Rarity rarity : Rarity.values()) {
            if (rarity.getRarityTitle().equalsIgnoreCase(rarityTitle)) {
                return rarity;
            }
        }
        throw new IllegalArgumentException("No enum constant for rarity title: " + rarityTitle);
    }

    @Override
    public String toString() {
        return "Rarity {" +
                "rarityTitle='" + rarityTitle + '\'' +
                '}';
    }
}
