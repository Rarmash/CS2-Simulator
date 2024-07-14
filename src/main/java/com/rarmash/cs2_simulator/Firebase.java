package com.rarmash.cs2_simulator;

import com.google.api.core.ApiFuture;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.*;
import com.rarmash.cs2_simulator.enums.Gloves;
import com.rarmash.cs2_simulator.enums.Knife;
import com.rarmash.cs2_simulator.skinspecs.Rarity;
import com.rarmash.cs2_simulator.enums.Weapon;
import com.rarmash.cs2_simulator.skinspecs.WeaponType;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.ExecutionException;

public class Firebase {
    private static Firestore db;
    public static void initialize() {

        try {
            db = FirestoreOptions.newBuilder()
                    .setCredentials(GoogleCredentials.fromStream(
                            Objects.requireNonNull(
                                    Firebase.class.getClassLoader().getResourceAsStream("firebaseConfig.json")
                            )))
                    .build()
                    .getService();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public static ArrayList<Skin> getSkinsFromCase(String caseId) {
        ArrayList<Skin> skins = new ArrayList<>();
        DocumentReference caseRef = db.collection("Cases").document(caseId);
        try {
            DocumentSnapshot caseSnap = caseRef.get().get();
            if (caseSnap.exists()) {
                List<String> skinIds = (List<String>) caseSnap.get("skins");
                for (String skinId: skinIds) {
                    DocumentReference skinRef = db.collection("Skins").document(skinId);
                    DocumentSnapshot skinSnap = skinRef.get().get();
                    if (skinSnap.exists()) {
                        Rarity rarity = Rarity.fromString(skinSnap.getString("rarity"));
                        WeaponType weaponType = WeaponType.fromString(skinSnap.getString("weaponType"));
                        if (weaponType != WeaponType.KNIFE && weaponType != WeaponType.GLOVES) {
                            Weapon weapon = Weapon.fromString(skinSnap.getString("weapon"));
                            skins.add(new Skin(
                                    Integer.parseInt(skinSnap.getId()),
                                    skinSnap.getString("name"),
                                    skinSnap.getDouble("float_top"),
                                    skinSnap.getDouble("float_bottom"),
                                    skinSnap.getBoolean("isSouvenir"),
                                    rarity,
                                    weaponType,
                                    weapon
                            ));
                        } else if (weaponType == WeaponType.KNIFE) {
                            Knife knife = Knife.fromString(skinSnap.getString("knife"));
                            skins.add(new Skin(
                                    Integer.parseInt(skinSnap.getId()),
                                    skinSnap.getString("name"),
                                    skinSnap.getDouble("float_top"),
                                    skinSnap.getDouble("float_bottom"),
                                    skinSnap.getBoolean("isSouvenir"),
                                    rarity,
                                    weaponType,
                                    knife
                            ));
                        } else if (weaponType == WeaponType.GLOVES) {
                            Gloves gloves = Gloves.fromString(skinSnap.getString("gloves"));
                            skins.add(new Skin(
                                    Integer.parseInt(skinSnap.getId()),
                                    skinSnap.getString("name"),
                                    skinSnap.getDouble("float_top"),
                                    skinSnap.getDouble("float_bottom"),
                                    skinSnap.getBoolean("isSouvenir"),
                                    rarity,
                                    weaponType,
                                    gloves
                            ));
                        }
                    }
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException(e);
        }
        return skins;
    }

    public static List<QueryDocumentSnapshot> getCaseList() {
        List<QueryDocumentSnapshot> caseList = new ArrayList<>();
        try {
            ApiFuture<QuerySnapshot> future = db.collection("Cases").get();
            List<QueryDocumentSnapshot> documents = future.get().getDocuments();
            caseList.addAll(documents);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException(e);
        }
        caseList.sort(Comparator.comparingInt(doc -> Integer.parseInt(doc.getId())));
        return caseList;
    }

    public static Case getLastCase() {
        List<QueryDocumentSnapshot> caseList = getCaseList();
        if (caseList.isEmpty()) {
            return null;
        }
        QueryDocumentSnapshot lastCaseSnapshot = caseList.get(caseList.size() - 1);
        int caseId = Integer.parseInt(lastCaseSnapshot.getId());
        String caseName = (String) lastCaseSnapshot.get("name");
        ArrayList<Skin> caseSkins = getSkinsFromCase(lastCaseSnapshot.getId());
        return new Case(caseId, caseName, caseSkins);
    }

    public static BufferedImage getCaseImage(String caseId) {
        DocumentReference caseRef = db.collection("Cases").document(caseId);
        try {
            DocumentSnapshot caseSnap = caseRef.get().get();
            if (caseSnap.exists()) {
                String imageUrl = caseSnap.getString("caseImage");
                URL url = new URL(imageUrl);
                return ImageIO.read(url);
            }
        } catch (InterruptedException | ExecutionException | IOException e) {
            throw new RuntimeException(e);
        }
        return null;
    }

    public static BufferedImage getSkinImage(String skinId) {
        DocumentReference skinRef = db.collection("Skins").document(skinId);
        try {
            DocumentSnapshot skinSnap = skinRef.get().get();
            if (skinSnap.exists()) {
                String imageUrl = skinSnap.getString("skinImage");
                URL url = new URL(imageUrl);
                return ImageIO.read(url);
            }
        } catch (InterruptedException | ExecutionException | IOException e) {
            throw new RuntimeException(e);
        }
        return null;
    }

    public static int getTotalUniqueSkins() {
        try {
            ApiFuture<QuerySnapshot> future = db.collection("Skins").get();
            return future.get().size();
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException(e);
        }
    }

    public static int getTotalSkinsInCases() {
        int totalSkins = 0;
        List<QueryDocumentSnapshot> caseList = getCaseList();
        for (QueryDocumentSnapshot caseSnapshot: caseList) {
            totalSkins += getSkinsFromCase(caseSnapshot.getId()).size();
        }
        return totalSkins;
    }
}