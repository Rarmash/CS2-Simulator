package com.rarmash.cs2_simulator.tools;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.google.api.core.ApiFuture;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.*;
import com.google.cloud.firestore.FirestoreOptions;

import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.ExecutionException;

public class FirestoreJsonExporter {

    private final Firestore db;
    private final ObjectMapper objectMapper;

    public FirestoreJsonExporter() {
        try {
            db = FirestoreOptions.newBuilder()
                    .setCredentials(GoogleCredentials.fromStream(
                            Objects.requireNonNull(
                                    getClass().getClassLoader().getResourceAsStream("firebaseConfig.json")
                            )
                    ))
                    .build()
                    .getService();
        } catch (IOException e) {
            throw new RuntimeException("Failed to init Firestore", e);
        }

        objectMapper = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);
    }

    public void exportAll() throws ExecutionException, InterruptedException, IOException {
        exportCollection("Cases", "export/cases.json");
        exportCollection("Skins", "export/skins.json");
    }

    private void exportCollection(String collectionName, String outputPath)
            throws ExecutionException, InterruptedException, IOException {

        ApiFuture<QuerySnapshot> future = db.collection(collectionName).get();
        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        List<Map<String, Object>> result = new ArrayList<>();

        for (QueryDocumentSnapshot doc : documents) {
            Map<String, Object> data = new LinkedHashMap<>();
            data.put("id", doc.getId());

            Map<String, Object> firestoreFields = doc.getData();
            if (firestoreFields != null) {
                data.putAll(firestoreFields);
            }

            result.add(data);
        }

        File outFile = new File(outputPath);
        File parent = outFile.getParentFile();
        if (parent != null && !parent.exists()) {
            parent.mkdirs();
        }

        objectMapper.writeValue(outFile, result);
        System.out.println("Exported " + collectionName + " -> " + outFile.getAbsolutePath());
    }

    public static void main(String[] args) throws Exception {
        new FirestoreJsonExporter().exportAll();
    }
}