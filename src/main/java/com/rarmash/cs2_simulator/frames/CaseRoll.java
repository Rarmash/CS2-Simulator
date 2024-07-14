package com.rarmash.cs2_simulator.frames;

import com.rarmash.cs2_simulator.Case;
import com.rarmash.cs2_simulator.Skin;
import com.rarmash.cs2_simulator.simulators.CaseOdds;
import com.rarmash.cs2_simulator.simulators.CaseSimulator;
import com.rarmash.cs2_simulator.skinspecs.FloatValue;
import com.rarmash.cs2_simulator.skinspecs.WeaponType;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Collections;

public class CaseRoll extends JFrame {
    private JPanel animationPanel;
    private ArrayList<Skin> skins;
    private Skin selectedSkin;
    private Timer timer;
    private int currentPosition;
    private final int animationDuration = 6000; // Длительность анимации в миллисекундах
    private final int framesPerSecond = 60; // Число кадров в секунду
    private final int frameDelay = 1000 / framesPerSecond; // Задержка между кадрами в миллисекундах
    private final int scrollSpeed = 5; // Скорость прокрутки в пикселях за кадр

    public CaseRoll(Case caseObj) {
        setTitle("Opening Case...");
        setSize(800, 600); // Размеры фрейма
        setResizable(false);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null); // Центрируем фрейм на экране
        setLayout(new BorderLayout());

        initializeAnimationPanel();
        startScrollAnimation(caseObj);
    }

    private void initializeAnimationPanel() {
        animationPanel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                if (skins != null) {
                    drawScrollingSkins((Graphics2D) g);
                }
                if (selectedSkin != null) {
                    displaySelectedSkin(g);
                }
            }
        };
        animationPanel.setBackground(Color.BLACK);
        add(animationPanel, BorderLayout.CENTER);
    }

    private void startScrollAnimation(Case caseObj) {
        skins = new ArrayList<>(caseObj.getSkins());
        Collections.shuffle(skins);

        timer = new Timer(frameDelay, null);
        timer.addActionListener(new ActionListener() {
            private final long startTime = System.currentTimeMillis();
            private int currentPosition = 0;
            private int lastPosition = 0;

            @Override
            public void actionPerformed(ActionEvent e) {
                long elapsed = System.currentTimeMillis() - startTime;

                currentPosition += scrollSpeed;
                if (currentPosition >= animationPanel.getWidth()) {
                    currentPosition = 0;
                }

                animationPanel.repaint();

                if (elapsed > animationDuration) {
                    timer.stop();
                    selectedSkin = openCase(caseObj);
                    stopAtSelectedSkin();
                }
            }

            private void stopAtSelectedSkin() {
                final int stopDuration = 1000; // Длительность остановки на выбранном скине в миллисекундах
                final int stopFrames = framesPerSecond * stopDuration / 1000; // Количество кадров для остановки

                // Запускаем таймер для остановки на выбранном скине
                Timer stopTimer = new Timer(frameDelay, null);
                stopTimer.addActionListener(new ActionListener() {
                    private int stopFrameCount = 0;

                    @Override
                    public void actionPerformed(ActionEvent e) {
                        stopFrameCount++;

                        if (stopFrameCount >= stopFrames) {
                            stopTimer.stop();
                        }

                        animationPanel.repaint();
                    }
                });
                stopTimer.start();
            }
        });
        timer.start();
    }

    private void drawScrollingSkins(Graphics2D g2d) {
        int panelHeight = animationPanel.getHeight();
        int x = -currentPosition;

        for (Skin skin : skins) {
            try {
                BufferedImage scaledSkinImage = resizeImage(skin.getSkinImage(), panelHeight);
                g2d.drawImage(scaledSkinImage, x, 0, null);
                x += scaledSkinImage.getWidth();
            } catch (Exception ex) {
                throw new RuntimeException(ex);
            }
        }
    }

    private void displaySelectedSkin(Graphics g) {
        int panelWidth = animationPanel.getWidth();
        int panelHeight = animationPanel.getHeight();

        try {
            BufferedImage scaledSkinImage = resizeImage(selectedSkin.getSkinImage(), panelHeight);
            int x = (panelWidth - scaledSkinImage.getWidth()) / 2;
            int y = (panelHeight - scaledSkinImage.getHeight()) / 2;
            g.drawImage(scaledSkinImage, x, y, null);
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    private Skin openCase(Case caseObj) {
        CaseOdds finalExterior = CaseSimulator.getRandomExterior();
        Skin item = CaseSimulator.selectSkin(caseObj.getSkins(), finalExterior);

        if (item.getWeaponType() != WeaponType.GLOVES) {
            item.setIsStattrak(CaseSimulator.generateStattrak());
        } else {
            item.setIsStattrak(false);
        }
        if (!(item.getWeaponType() == WeaponType.KNIFE && item.getName().equals("Vanilla"))) {
            item.setSkinFloat(CaseSimulator.generateFloat(item.getFloat_top(), item.getFloat_bottom()));
            item.setExterior(FloatValue.getExterior(item.getSkinFloat()));
        }

        return item;
    }

    private BufferedImage resizeImage(BufferedImage originalImage, int targetHeight) {
        int originalHeight = originalImage.getHeight();
        int originalWidth = originalImage.getWidth();
        int targetWidth = (originalWidth * targetHeight) / originalHeight;

        BufferedImage resizedImage = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_ARGB);
        Graphics2D graphics2D = resizedImage.createGraphics();

        graphics2D.drawImage(originalImage, 0, 0, targetWidth, targetHeight, null);
        graphics2D.dispose();

        return resizedImage;
    }
}
