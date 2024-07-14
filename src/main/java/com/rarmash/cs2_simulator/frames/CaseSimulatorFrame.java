package com.rarmash.cs2_simulator.frames;

import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.rarmash.cs2_simulator.Case;
import com.rarmash.cs2_simulator.Firebase;

import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.ArrayList;

public class CaseSimulatorFrame extends JFrame {
    public CaseSimulatorFrame(ArrayList<Case> cases) {
        setTitle("Case simulator");
        setSize(1366, 768);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        // setResizable(false);
        setLocationRelativeTo(null);

        JPanel panel = new JPanel(new GridLayout(0, 4, 10, 10));
        panel.setBackground(Color.BLACK);

        for (Case caseObj: cases) {
            try {
                BufferedImage caseImage = caseObj.getCaseImage();
                ImageIcon icon = new ImageIcon(caseImage);
                JButton button = new JButton(icon);
                button.setVerticalTextPosition(SwingConstants.BOTTOM);
                button.setHorizontalTextPosition(SwingConstants.CENTER);
                button.setText(caseObj.getName());
                button.setBackground(Color.DARK_GRAY);
                button.setForeground(Color.WHITE);
                button.setBorderPainted(false);
                button.setFocusPainted(false);
                button.addActionListener(e -> new OpenCaseFrame(caseObj).setVisible(true));
                panel.add(button);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        JScrollPane scrollPane = new JScrollPane(panel);
        add(scrollPane);
    }
}
