package com.rarmash.cs2_simulator;

import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.rarmash.cs2_simulator.frames.LoadingFrame;
import com.rarmash.cs2_simulator.frames.MainFrame;

import javax.imageio.ImageIO;
import javax.swing.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DataStore {
    private static ArrayList<Case> cases = new ArrayList<>();
    private static ArrayList<Skin> skins = new ArrayList<>();
    private static Map<Integer, byte[]> caseImages = new HashMap<>();
    private static Map<Integer, byte[]> skinImages = new HashMap<>();
    private static final String CACHE_FILE = "cache.dat";

    public static void initialize() {
        File cacheFile = new File(CACHE_FILE);
        if (cacheFile.exists()) {
            try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream(cacheFile))) {
                cases = (ArrayList<Case>) ois.readObject();
                skins = (ArrayList<Skin>) ois.readObject();
                caseImages = (Map<Integer, byte[]>) ois.readObject();
                skinImages = (Map<Integer, byte[]>) ois.readObject();
                Case lastCaseInFirestore = Firebase.getLastCase();
                if (!cases.contains(lastCaseInFirestore)) {
                    updateData();
                } else {
                    SwingUtilities.invokeLater(() -> new MainFrame().setVisible(true));
                }
            } catch (IOException | ClassNotFoundException e) {
                throw new RuntimeException(e);
            }
        } else {
            updateData();
        }
    }

    private static void updateData() {
        new Thread(() -> {
            List<QueryDocumentSnapshot> caseList = Firebase.getCaseList();
            int totalSkins = Firebase.getTotalUniqueSkins();
            int loadedSkins = 0;

            LoadingFrame loadingFrame = new LoadingFrame();
            loadingFrame.setVisible(true);

            for (QueryDocumentSnapshot caseSnapshot: caseList) {
                int caseId = Integer.parseInt(caseSnapshot.getId());
                String caseName = (String) caseSnapshot.get("name");
                ArrayList<Skin> caseSkins = Firebase.getSkinsFromCase(caseSnapshot.getId());
                BufferedImage caseImage = Firebase.getCaseImage(caseSnapshot.getId());
                cases.add(new Case(caseId, caseName, caseSkins));
                caseImages.put(caseId, bufferedImageToByteArray(caseImage));
                System.out.println(caseName + " added");
                skins.addAll(caseSkins);
                for (Skin skin: caseSkins) {
                    BufferedImage skinImage = Firebase.getSkinImage(String.valueOf(skin.getId()));
                    skinImages.put(skin.getId(), bufferedImageToByteArray(skinImage));
                    loadedSkins++;
                    int progress = (int) ((double) loadedSkins / totalSkins * 100);
                    loadingFrame.updateProgress(progress);
                }
            }
            try (ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream(CACHE_FILE))) {
                oos.writeObject(cases);
                oos.writeObject(skins);
                oos.writeObject(caseImages);
                oos.writeObject(skinImages);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }

            loadingFrame.dispose();

            SwingUtilities.invokeLater(() -> new MainFrame().setVisible(true));

        }).start();
    }


    public static ArrayList<Case> getCases() {
        return cases;
    }

    public static Case getCase(int caseId) {
        for (Case caseObj: cases) {
            if (caseObj.getId() == caseId) {
                return caseObj;
            }
        }
        return null;
    }

    public static BufferedImage getCaseImage(int caseId) {
        return byteArrayToBufferedImage(caseImages.get(caseId));
    }

    public static BufferedImage getSkinImage(int skinId) {
        return byteArrayToBufferedImage(skinImages.get(skinId));
    }

    public static Skin getSkin(String skinName) {
        for (Skin skin: skins) {
            if (skin.getName().equals(skinName)) {
                return skin;
            }
        }
        return null;
    }

    public static Case getRandomCase() {
        return cases.get((int) (Math.random() * cases.size()));
    }

    private static byte[] bufferedImageToByteArray(BufferedImage image) {
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            ImageIO.write(image, "png", baos);
            return baos.toByteArray();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static BufferedImage byteArrayToBufferedImage(byte[] bytes) {
        try (ByteArrayInputStream bais = new ByteArrayInputStream(bytes)) {
            return ImageIO.read(bais);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
