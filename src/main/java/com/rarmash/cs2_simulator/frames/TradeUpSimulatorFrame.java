package com.rarmash.cs2_simulator.frames;

import javax.swing.*;

public class TradeUpSimulatorFrame extends JFrame {
    public TradeUpSimulatorFrame() {
        setTitle("Trade-Up Contract Simulator");
        setSize(640, 480);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);

        JLabel label = new JLabel("Здесь будет меню создания контрактов.");
        add(label);
    }
}
