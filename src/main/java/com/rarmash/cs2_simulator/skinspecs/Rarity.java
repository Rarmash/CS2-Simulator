package com.rarmash.cs2_simulator.skinspecs;

public enum Rarity {
    CONTRABAND ("Contraband"),
    EXTRAORDINARY ("Extraordinary"),
    COVERT ("Covert"),
    CLASSIFIED ("Classified"),
    RESTRICTED ("Restricted"),
    MIL_SPEC ("Mil-Spec Grade"),
    INDUSTRIAL ("Industrial Grade"),
    CONSUMER ("Consumer Grade");

    private String rarityTitle;

    Rarity(String rarityTitle) {
        this.rarityTitle = rarityTitle;
    }

    public String getRarityTitle() {
        return rarityTitle;
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
