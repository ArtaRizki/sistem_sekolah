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
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
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
import java.io.File;
import java.io.FileOutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import io.flutter.embedding.android.FlutterActivity;

public class FaceDetectionActivity extends FlutterActivity implements View.OnClickListener {
    PreviewView previewView;
    Button btnTakePhoto;
    File output;
    ExecutorService executorService;
    CameraSelector cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA;
    ImageCapture imageCapture;
    ImageAnalysis imageAnalysis;
    FaceDetector faceDetector;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_face_detection);

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

        startCamera();
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
                    Image mediaImage = imageProxy.getImage();
                    if (mediaImage != null) {
                        InputImage image = InputImage.fromMediaImage(mediaImage, imageProxy.getImageInfo().getRotationDegrees());
                        faceDetector.process(image)
                                .addOnSuccessListener(faces -> {
                                    runOnUiThread(() -> {
                                        if (!faces.isEmpty()) {
                                            btnTakePhoto.setEnabled(true);
                                            btnTakePhoto.setText("Ambil Foto");
                                        } else {
                                            btnTakePhoto.setEnabled(false);
                                            btnTakePhoto.setText("Wajah Tidak Terdeteksi");
                                        }
                                    });
                                })
                                .addOnCompleteListener(task -> imageProxy.close());
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
            takePicture();
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
}
