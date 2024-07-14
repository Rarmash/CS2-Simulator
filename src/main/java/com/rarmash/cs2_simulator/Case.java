package com.rarmash.cs2_simulator;

import java.awt.image.BufferedImage;
import java.io.Serializable;
import java.util.ArrayList;

public class Case implements Serializable {
    private final int id;
    private final String name;
    private final ArrayList<Skin> skins;

    public Case(int id, String name, ArrayList<Skin> skins) {
        this.id = id;
        this.name = name;
        this.skins = skins;
    }

    public String getName() {
        return name;
    }

    public BufferedImage getCaseImage() {
        return DataStore.getCaseImage(id);
    }

    public ArrayList<Skin> getSkins() {
        return skins;
    }

    public int getId() {
        return id;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null || getClass() != obj.getClass()) {
            return false;
        }
        Case caseObj = (Case) obj;
        return id == caseObj.id;
    }
}
