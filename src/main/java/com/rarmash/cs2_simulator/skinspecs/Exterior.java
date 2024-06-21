package com.rarmash.cs2_simulator.skinspecs;

public enum Exterior {
    FACTORY_NEW ("Factory New"),
    MINIMAL_WEAR ("Minimal Wear"),
    FIELD_TESTED ("Field-Tested"),
    WELL_WORN ("Well-Worn"),
    BATTLE_SCARRED ("Battle-Scarred");

    private String exteriorTitle;

    Exterior(String exteriorTitle) {
        this.exteriorTitle = exteriorTitle;
    }

    public String getExteriorTitle() {
        return exteriorTitle;
    }

    @Override
    public String toString() {
        return "Exterior {" +
                "exteriorTitle='" + exteriorTitle + '\'' +
                '}';
    }
}
