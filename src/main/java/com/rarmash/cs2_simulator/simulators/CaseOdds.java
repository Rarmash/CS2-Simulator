package com.rarmash.cs2_simulator.simulators;

public enum CaseOdds {
    MIl_SPEC (0.7992327),
    RESTRICTED (0.1598465),
    CLASSIFIED (0.0319693),
    COVERT (0.0063939),
    SPECIAL_ITEM (0.0025575);

    private final double rarityOdds;

    CaseOdds(double rarityOdds) {
        this.rarityOdds = rarityOdds;
    }

    public double getRarityOdds() {
        return rarityOdds;
    }
}
