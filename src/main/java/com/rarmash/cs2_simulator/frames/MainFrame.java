package com.rarmash.cs2_simulator.frames;

import com.rarmash.cs2_simulator.DataStore;
import com.rarmash.cs2_simulator.Firebase;

import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;

public class MainFrame extends JFrame {
    public MainFrame() {
        setTitle("CS2 simulator");
        setSize(640, 480);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setResizable(false);
        setLocationRelativeTo(null);

        JLabel label = new JLabel("Welcome to CS2 simulator!", SwingConstants.CENTER);
        label.setForeground(Color.WHITE);
        label.setAlignmentX(Component.CENTER_ALIGNMENT);

        BufferedImage caseImage = DataStore.getRandomCase().getCaseImage();
        JLabel imageLabel = null;
        if (caseImage != null) {
            ImageIcon icon = new ImageIcon(caseImage);
            imageLabel = new JLabel(icon, SwingConstants.CENTER);
            imageLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        }

        JButton caseSimulatorButton = new JButton("Case simulator");
        caseSimulatorButton.setAlignmentX(Component.CENTER_ALIGNMENT);
        JButton tradeUpSimulatorButton = new JButton("Trade-Up Contract simulator");
        tradeUpSimulatorButton.setAlignmentX(Component.CENTER_ALIGNMENT);

        caseSimulatorButton.addActionListener(e -> new CaseSimulatorFrame(DataStore.getCases()).setVisible(true));
        tradeUpSimulatorButton.addActionListener(e -> new TradeUpSimulatorFrame().setVisible(false));

        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.PAGE_AXIS));
        panel.setBackground(Color.BLACK);
        panel.add(label);
        if (imageLabel != null) {
            panel.add(imageLabel);
        }
        panel.add(caseSimulatorButton);
        panel.add(tradeUpSimulatorButton);

        add(panel);
    }
}
