package com.rarmash.cs2_simulator;

import com.google.api.core.ApiFuture;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.*;
import com.rarmash.cs2_simulator.enums.Gloves;
import com.rarmash.cs2_simulator.enums.Knife;
import com.rarmash.cs2_simulator.skinspecs.Rarity;
import com.rarmash.cs2_simulator.enums.Weapon;
import com.rarmash.cs2_simulator.skinspecs.WeaponType;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

public class Firebase {
    private static Firestore db;
    public Firebase() {
        String firebaseConfig = "firebaseConfig.json";

        try {
            db = FirestoreOptions.newBuilder()
                    .setCredentials(GoogleCredentials.fromStream(new FileInputStream(firebaseConfig)))
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
            e.printStackTrace();
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
            e.printStackTrace();
        }
        return caseList;
    }
}
