package com.rarmash.cs2_simulator.frames;

import javax.swing.*;

public class LoadingFrame extends JFrame {
    private final JProgressBar progressBar;

    public LoadingFrame() {
        setTitle("Loading Skins...");
        setSize(300, 100);
        setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        setLocationRelativeTo(null);
        setResizable(false);

        progressBar = new JProgressBar();
        progressBar.setStringPainted(true);

        JPanel panel = new JPanel();
        panel.add(progressBar);

        add(panel);
    }

    public void updateProgress(int progress) {
        progressBar.setValue(progress);
    }
}