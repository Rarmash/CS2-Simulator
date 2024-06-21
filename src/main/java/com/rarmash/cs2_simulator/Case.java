package com.rarmash.cs2_simulator;

import java.util.ArrayList;

public class Case {
    private String name;
    private ArrayList<Skin> skins;

    public Case(String name, ArrayList<Skin> skins) {
        this.name = name;
        this.skins = skins;
    }

    public String getName() {
        return name;
    }

    public ArrayList<Skin> getSkins() {
        return skins;
    }
}
