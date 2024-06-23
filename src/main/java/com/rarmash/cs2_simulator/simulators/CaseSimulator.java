package com.rarmash.cs2_simulator.simulators;

import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.rarmash.cs2_simulator.Case;
import com.rarmash.cs2_simulator.Firebase;
import com.rarmash.cs2_simulator.Skin;
import com.rarmash.cs2_simulator.skinspecs.*;

import java.util.*;

import static com.rarmash.cs2_simulator.Firebase.getCaseList;

public class CaseSimulator {
    public CaseSimulator() {
        Scanner scanner = new Scanner(System.in);

        List<QueryDocumentSnapshot> documents = getCaseList();

        Collections.sort(documents, Comparator.comparingInt(o -> Integer.parseInt(o.getId())));

        System.out.println("Choose case to start opening:");
        int n = 1;
        for (QueryDocumentSnapshot document: documents) {
            System.out.println(n + ". " + document.get("name"));
            n++;
        }

        int input = scanner.nextInt();

        Case caseObj = new Case(
                (String) getCaseList().get(input - 1).get("name"),
                Firebase.getCaseImage(String.valueOf(input)),
                Firebase.getSkinsFromCase(String.valueOf(input))
        );

        while (true) {
            CaseOdds finalExterior = getRandomExterior();

            Skin item = selectSkin(caseObj.getSkins(), finalExterior);
            item.setIsStattrak(generateStattrak());
            if (!(item.getWeaponType() == WeaponType.KNIFE && item.getName() == "Vanilla")) {
                item.setSkinFloat(generateFloat(item.getFloat_top(), item.getFloat_bottom()));
                item.setExterior(FloatValue.getExterior(item.getSkinFloat()));
            }

            System.out.println(item);

            new Scanner(System.in).nextLine();
        }
    }

    private CaseOdds getRandomExterior() {
        Random rand = new Random();
        double randomValue = rand.nextDouble();

        double cumulativeProbability = 0.0;

        for (CaseOdds odds: CaseOdds.values()) {
            cumulativeProbability += odds.getRarityOdds();
            if (randomValue <= cumulativeProbability) {
                return odds;
            }
        }
        return CaseOdds.MIl_SPEC;
    }

    private ArrayList<Skin> sortSkins(ArrayList<Skin> skins, CaseOdds exterior) {
        ArrayList<Skin> sortedSkins = new ArrayList<>();
        switch (exterior) {
            case MIl_SPEC -> {
                for (Skin skin: skins) {
                    if (skin.getRarity() == Rarity.MIL_SPEC) {
                        sortedSkins.add(skin);
                    }
                }
            }
            case RESTRICTED -> {
                for (Skin skin: skins) {
                    if (skin.getRarity() == Rarity.RESTRICTED) {
                        sortedSkins.add(skin);
                    }
                }
            }
            case CLASSIFIED -> {
                for (Skin skin: skins) {
                    if (skin.getRarity() == Rarity.CLASSIFIED) {
                        sortedSkins.add(skin);
                    }
                }
            }
            case COVERT -> {
                for (Skin skin: skins) {
                    if ((skin.getRarity() == Rarity.COVERT || skin.getRarity() == Rarity.CONTRABAND)
                            && skin.getWeaponType() != WeaponType.KNIFE && skin.getWeaponType() != WeaponType.GLOVES) {
                        sortedSkins.add(skin);
                    }
                }
            }
            case SPECIAL_ITEM -> {
                for (Skin skin: skins) {
                    if ((skin.getRarity() == Rarity.COVERT || skin.getRarity() == Rarity.CONTRABAND)
                            && (skin.getWeaponType() == WeaponType.KNIFE || skin.getWeaponType() == WeaponType.GLOVES)) {
                        sortedSkins.add(skin);
                    }
                }
            }
        }
        return sortedSkins;
    }

    private double generateFloat(double float_top, double float_bottom) {
        Random rand = new Random();
        double random = rand.nextDouble();
        return float_top + random * (float_bottom - float_top);
    }

    private Skin selectSkin(ArrayList<Skin> skins, CaseOdds exterior) {
        Skin skin = null;
        switch (exterior) {
            case MIl_SPEC -> {
                ArrayList<Skin> mil_spec_skins = sortSkins(skins, CaseOdds.MIl_SPEC);
                Random generator = new Random();
                int randomItem = generator.nextInt(mil_spec_skins.size());
                skin = mil_spec_skins.get(randomItem);
            }
            case RESTRICTED -> {
                ArrayList<Skin> restricted_skins = sortSkins(skins, CaseOdds.RESTRICTED);
                Random generator = new Random();
                int randomItem = generator.nextInt(restricted_skins.size());
                skin = restricted_skins.get(randomItem);
            }
            case CLASSIFIED -> {
                ArrayList<Skin> classified_skins = sortSkins(skins, CaseOdds.CLASSIFIED);
                Random generator = new Random();
                int randomItem = generator.nextInt(classified_skins.size());
                skin = classified_skins.get(randomItem);
            }
            case COVERT -> {
                ArrayList<Skin> covert_skins = sortSkins(skins, CaseOdds.COVERT);
                Random generator = new Random();
                int randomItem = generator.nextInt(covert_skins.size());
                skin = covert_skins.get(randomItem);
            }
            case SPECIAL_ITEM -> {
                ArrayList<Skin> special_skins = sortSkins(skins, CaseOdds.SPECIAL_ITEM);
                Random generator = new Random();
                int randomItem = generator.nextInt(special_skins.size());
                skin = special_skins.get(randomItem);
            }
        }
        return skin;
    }

    private boolean generateStattrak() {
        return new Random().nextInt(10) == 0;
    }
}
