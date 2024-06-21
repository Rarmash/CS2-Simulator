package com.rarmash.cs2_simulator.enums;

public enum Gloves {
    BLOODHOUND ("Bloodhound Gloves"),
    BROKEN_FANG ("Broken Fang Gloves"),
    DRIVER ("Driver Gloves"),
    HAND_WRAPS ("Hand Wraps"),
    HYDRA ("Hydra Gloves"),
    MOTO ("Moto Gloves"),
    SPECIALIST ("Specialist Gloves"),
    SPORT ("Sport Gloves");

    private final String glovesTitle;

    Gloves(String knifeTitle) {
        this.glovesTitle = knifeTitle;
    }

    public String getGlovesTitle() {
        return glovesTitle;
    }

    public static Gloves fromString(String glovesTitleString) {
        for (Gloves gloves : Gloves.values()) {
            if (gloves.getGlovesTitle().equalsIgnoreCase(glovesTitleString)) {
                return gloves;
            }
        }
        throw new IllegalArgumentException("No enum constant for gloves title: " + glovesTitleString);
    }

    @Override
    public String toString() {
        return "Knife {" +
                "knifeTitle='" + glovesTitle + '\'' +
                '}';
    }
}
