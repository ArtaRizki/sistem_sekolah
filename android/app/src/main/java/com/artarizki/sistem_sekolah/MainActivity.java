package com.artarizki.sistem_sekolah;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.Nullable;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.artarizki.sistem_sekolah/face";
    MethodChannel.Result methodChannelResult;
    FaceHelper faceHelper = new FaceHelper();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    methodChannelResult = result;
                    switch (call.method) {
                        case "initFaceHelper":
                            try {
                                String modelPath = call.argument("modelPath");
                                faceHelper.init(this, modelPath);
                                result.success(true);
                            } catch (Exception e) {
                                result.error("INIT_ERROR", e.getMessage(), null);
                            }
                            break;
                        case "startFaceCapture":
                            startActivityForResult(new Intent(MainActivity.this, FaceDetectionActivity.class), 202);
                            break;
                        case "getEmbedding":
                            String path = call.argument("imagePath");
                            float[] embedding = faceHelper.getEmbedding(path);
                            if (embedding != null) {
                                List<Double> list = new ArrayList<>();
                                for (float f : embedding) list.add((double) f);
                                result.success(list);
                            } else {
                                result.error("EMBEDDING_ERROR", "Failed to generate embedding", null);
                            }
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 202 && methodChannelResult != null) {
            if (resultCode == RESULT_OK && data != null) {
                methodChannelResult.success(data.getStringExtra("result"));
            } else {
                methodChannelResult.success(null);
            }
            methodChannelResult = null;
        }
    }
}
