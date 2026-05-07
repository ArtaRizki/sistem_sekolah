package com.artarizki.sistem_sekolah;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.Image;
import android.os.Bundle;
import android.util.Size;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageCapture;
import androidx.camera.core.ImageCaptureException;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.face.FaceDetection;
import com.google.mlkit.vision.face.FaceDetector;
import com.google.mlkit.vision.face.FaceDetectorOptions;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.constraintlayout.widget.ConstraintLayout;
import java.io.File;
import java.io.FileOutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class FaceDetectionActivity extends AppCompatActivity implements View.OnClickListener {
    private static final int PERMISSION_CODE = 1001;
    private static final String[] REQUIRED_PERMISSIONS = new String[]{Manifest.permission.CAMERA};

    PreviewView previewView;
    Button btnTakePhoto;
    File output;
    ExecutorService executorService;
    CameraSelector cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA;
    ImageCapture imageCapture;
    ImageAnalysis imageAnalysis;
    FaceDetector faceDetector;
    private boolean isProcessingCapture = false;
    private long faceDetectedStartTime = 0;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_face_detection);

        View root = findViewById(R.id.main);
        ViewCompat.setOnApplyWindowInsetsListener(root, (v, insets) -> {
            int bottom = insets.getInsets(WindowInsetsCompat.Type.systemBars()).bottom;
            v.setPadding(0, 0, 0, bottom);
            return insets;
        });

        previewView = findViewById(R.id.viewFinder);
        btnTakePhoto = findViewById(R.id.camera_capture_button);
        findViewById(R.id.btn_close).setOnClickListener(this);
        btnTakePhoto.setOnClickListener(this);

        executorService = Executors.newSingleThreadExecutor();
        output = new File(getCacheDir(), "captured_face.jpg");

        FaceDetectorOptions options = new FaceDetectorOptions.Builder()
                .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
                .build();
        faceDetector = FaceDetection.getClient(options);

        if (allPermissionsGranted()) {
            startCamera();
        } else {
            ActivityCompat.requestPermissions(this, REQUIRED_PERMISSIONS, PERMISSION_CODE);
        }
    }

    private boolean allPermissionsGranted() {
        for (String permission : REQUIRED_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_CODE) {
            if (allPermissionsGranted()) {
                startCamera();
            } else {
                Toast.makeText(this, "Izin kamera diperlukan untuk fitur ini", Toast.LENGTH_SHORT).show();
                finish();
            }
        }
    }

    private void startCamera() {
        ListenableFuture<ProcessCameraProvider> cameraProviderFuture = ProcessCameraProvider.getInstance(this);
        cameraProviderFuture.addListener(() -> {
            try {
                ProcessCameraProvider cameraProvider = cameraProviderFuture.get();
                Preview preview = new Preview.Builder().build();
                preview.setSurfaceProvider(previewView.getSurfaceProvider());

                imageCapture = new ImageCapture.Builder().build();
                imageAnalysis = new ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build();

                imageAnalysis.setAnalyzer(executorService, imageProxy -> {
                    @SuppressWarnings("UnsafeOptInUsageError")
                    Image mediaImage = imageProxy.getImage();
                    if (mediaImage != null) {
                        InputImage image = InputImage.fromMediaImage(mediaImage, imageProxy.getImageInfo().getRotationDegrees());
                        faceDetector.process(image)
                                .addOnSuccessListener(faces -> {
                                    runOnUiThread(() -> {
                                        if (!faces.isEmpty()) {
                                            if (faceDetectedStartTime == 0) {
                                                faceDetectedStartTime = System.currentTimeMillis();
                                            }

                                            long elapsed = System.currentTimeMillis() - faceDetectedStartTime;
                                            if (elapsed >= 1000 && !isProcessingCapture) {
                                                isProcessingCapture = true;
                                                btnTakePhoto.setText("Mengambil Gambar...");
                                                takePicture();
                                            } else {
                                                btnTakePhoto.setEnabled(true);
                                                btnTakePhoto.setText("Tahan Sebentar... " + (1 - (elapsed / 1000)));
                                                // Just show "Tahan Sebentar..." if it's less than 1s
                                                btnTakePhoto.setText("Tahan Sebentar...");
                                            }
                                        } else {
                                            faceDetectedStartTime = 0;
                                            btnTakePhoto.setEnabled(false);
                                            btnTakePhoto.setText("Wajah Tidak Terdeteksi");
                                        }
                                    });
                                })
                                .addOnCompleteListener(task -> imageProxy.close());
                    } else {
                        imageProxy.close();
                    }
                });

                cameraProvider.unbindAll();
                cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageCapture, imageAnalysis);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, ContextCompat.getMainExecutor(this));
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.camera_capture_button) {
            if (!isProcessingCapture) {
                isProcessingCapture = true;
                takePicture();
            }
        } else if (v.getId() == R.id.btn_close) {
            finish();
        }
    }

    private void takePicture() {
        imageCapture.takePicture(new ImageCapture.OutputFileOptions.Builder(output).build(), executorService, new ImageCapture.OnImageSavedCallback() {
            @Override
            public void onImageSaved(@NonNull ImageCapture.OutputFileResults outputFileResults) {
                Intent intent = new Intent();
                intent.putExtra("result", output.getAbsolutePath());
                setResult(RESULT_OK, intent);
                finish();
            }

            @Override
            public void onError(@NonNull ImageCaptureException exception) {
                exception.printStackTrace();
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        executorService.shutdown();
    }
}

