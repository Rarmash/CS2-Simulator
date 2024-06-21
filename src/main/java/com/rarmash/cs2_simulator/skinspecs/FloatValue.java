package com.rarmash.cs2_simulator.skinspecs;

public class FloatValue {
    public static Exterior getExterior(double float_value) {
        if (float_value > 0.00 && float_value < 0.07) {
            return Exterior.FACTORY_NEW;
        } else if (float_value > 0.07 && float_value < 0.15) {
            return Exterior.MINIMAL_WEAR;
        } else if (float_value > 0.15 && float_value < 0.37) {
            return Exterior.FIELD_TESTED;
        } else if (float_value > 0.37 && float_value < 0.44) {
            return Exterior.WELL_WORN;
        } else if (float_value > 0.44 && float_value < 1.00) {
            return Exterior.BATTLE_SCARRED;
        } else {
            throw new IllegalArgumentException("Float value out of range: " + float_value);
        }
    }
}
