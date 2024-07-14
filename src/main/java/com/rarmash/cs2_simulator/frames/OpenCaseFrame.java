package com.rarmash.cs2_simulator.frames;

import com.rarmash.cs2_simulator.Case;
import com.rarmash.cs2_simulator.Skin;
import com.rarmash.cs2_simulator.skinspecs.Rarity;
import com.rarmash.cs2_simulator.skinspecs.WeaponType;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.List;
import java.util.Comparator;
import java.util.Objects;

public class OpenCaseFrame extends JFrame {

    public OpenCaseFrame(Case caseObj) {
        setTitle("Open " + caseObj.getName());
        setSize(1000, 750);
        setResizable(false);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());
        getContentPane().setBackground(Color.BLACK);

        initializeGUI(caseObj);
    }

    private void initializeGUI(Case caseObj) {
        addCaseImage(caseObj);
        addSkinsPanel(caseObj);
        addButtonPanel(caseObj);
    }

    private void addCaseImage(Case caseObj) {
        try {
            BufferedImage caseImage = caseObj.getCaseImage();
            caseImage = resizeImage(caseImage, 200);
            JLabel caseLabel = new JLabel(new ImageIcon(caseImage), SwingConstants.CENTER);
            add(caseLabel, BorderLayout.NORTH);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private void addButtonPanel(Case caseObj) {
        JPanel buttonPanel = new JPanel();
        buttonPanel.setPreferredSize(new Dimension(1000, 100));
        buttonPanel.setOpaque(false);

        JButton openCaseButton = new JButton("Open case");
        openCaseButton.addActionListener(e -> {
            // Открываем новое окно с анимацией открытия кейса
            openCaseAnimation(caseObj);
        });

        buttonPanel.add(openCaseButton);
        add(buttonPanel, BorderLayout.CENTER);
    }

    private void addSkinsPanel(Case caseObj) {
        JPanel skinsPanel = new JPanel();
        skinsPanel.setLayout(new GridLayout(0, 5, 10, 10));
        skinsPanel.setBackground(Color.BLACK);

        List<Skin> sortedSkins = caseObj.getSkins().stream()
            .sorted(Comparator.comparingInt(skin -> -Rarity.getRarityIndex(skin.getRarity())))
            .toList();

        for (Skin skin : sortedSkins) {
            if (skin.getWeaponType() != WeaponType.KNIFE && skin.getWeaponType() != WeaponType.GLOVES) {
                BufferedImage skinImage = resizeImage(skin.getSkinImage(), 100);
                skinImage = addRarityStripe(skinImage, skin.getRarity());
                JLabel skinLabel = new JLabel(new ImageIcon(skinImage), SwingConstants.CENTER);
                skinsPanel.add(skinLabel);
            } else {
                addSpecialItem(skinsPanel);
                break;
            }
        }

        add(skinsPanel, BorderLayout.SOUTH);
    }

    private void addSpecialItem(JPanel skinsPanel) {
        try {
            BufferedImage rareItemImage = ImageIO.read(Objects.requireNonNull(
                    OpenCaseFrame.class.getClassLoader().getResourceAsStream("rare_item.png")));
            rareItemImage = resizeImage(rareItemImage, 100);
            rareItemImage = addRarityStripe(rareItemImage, Rarity.CONTRABAND);
            JLabel rareItemLabel = new JLabel(new ImageIcon(rareItemImage), SwingConstants.CENTER);
            rareItemLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
            skinsPanel.add(rareItemLabel);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private void openCaseAnimation(Case caseObj) {
        // Создаем и отображаем новое окно с анимацией открытия кейса
        CaseRoll caseRoll = new CaseRoll(caseObj);
        caseRoll.setVisible(true);
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

    private BufferedImage addRarityStripe(BufferedImage originalImage, Rarity rarity) {
        int stripeWidth = 10;
        BufferedImage imageWithStripe = new BufferedImage(originalImage.getWidth() + stripeWidth, originalImage.getHeight(), BufferedImage.TYPE_INT_ARGB);
        Graphics2D g2d = imageWithStripe.createGraphics();

        g2d.setColor(rarity.getColor());
        g2d.fillRect(0, 0, stripeWidth, originalImage.getHeight());

        g2d.drawImage(originalImage, stripeWidth, 0, null);

        g2d.dispose();
        return imageWithStripe;
    }
}
