package com.rarmash.cs2_simulator;

import java.util.ArrayList;

public class Case {
    private final String name;
    private final String caseImage;
    private final ArrayList<Skin> skins;

    public Case(String name, String caseImage, ArrayList<Skin> skins) {
        this.name = name;
        this.caseImage = caseImage;
        this.skins = skins;
    }

    public String getName() {
        return name;
    }

    public String getCaseImage() {
        return caseImage;
    }

    public ArrayList<Skin> getSkins() {
        return skins;
    }
}
